require 'jackal-stacks'

module Jackal
  module Stacks
    # Stack builder
    class Builder < Callback

      include StackCommon

      # Setup callback
      def setup(*_)
        require 'sfn'
        require 'bogo-ui'
        require 'stringio'
        require 'openssl'
        require 'fileutils'
        require 'batali'
      end

      # Determine validity of message
      #
      # @param message [Carnivore::Message]
      # @return [Truthy, Falsey]
      def valid?(message)
        super do |payload|
          (!block_given? || yield(payload)) &&
            payload.get(:data, :stacks, :builder) &&
            payload.get(:data, :stacks, :asset) &&
            allowed?(payload)
        end
      end

      # Build or update stacks
      #
      # @param message [Carnivore::Message]
      def execute(message)
        failure_wrap(message) do |payload|
          directory = asset_store.unpack(asset_store.get(payload.get(:data, :stacks, :asset)), workspace(payload))
          begin
            unless(payload.get(:data, :stacks, :name))
              payload.set(:data, :stacks, :name, stack_name(payload))
            end
            unless(payload.get(:data, :stacks, :template))
              payload.set(:data, :stacks, :template, 'infrastructure')
            end
            store_stable_asset(payload, directory)
            begin
              stack = stacks_api.stacks.get(payload.get(:data, :stacks, :name))
            rescue
              stack = nil
            end
            if(stack)
              info "Stack currently exists. Applying update [#{stack}]"
              run_stack(payload, directory, :update)
              payload.set(:data, :stacks, :updated, true)
            else
              info "Stack does not currently exist. Building new stack [#{payload.get(:data, :stacks, :name)}]"
              init_provider(payload)
              run_stack(payload, directory, :create)
              payload.set(:data, :stacks, :created, true)
            end
          ensure
            FileUtils.rm_rf(directory)
          end
          job_completed(:stacks, payload, message)
        end
      end

      # Build configuration arguments for Sfn::Command execution
      #
      # @param payload [Smash]
      # @param directory [String] directory to unpacked asset
      # @return [Smash] stack command options hash
      def build_stack_args(payload, directory)
        Smash.new(
          :base_directory => File.join(directory, 'cloudformation'),
          :parameters => load_stack_parameters(payload, directory),
          :ui => Bogo::Ui.new(
            :app_name => 'JackalStacks',
            :defaults => true,
            :output_to => StringIO.new('')
          ),
          :interactive_parameters => false,
          :nesting_bucket => config.get(:orchestration, :bucket_name),
          :apply_nesting => true,
          :processing => true,
          :options => {
            :disable_rollback => true,
            :capabilities => ['CAPABILITY_IAM']
          },
          :credentials => config.get(:orchestration, :api, :credentials),
          :file => payload.fetch(:data, :stacks, :template, config.get(:default_template_path)),
          :file_path_prompt => false,
          :poll => false
        )
      end

      # Extract any custom parameters from asset store if available,
      # and merge any parameters provided via payload, and finally
      # merge any parameters provided via configuration
      #
      # @param payload [Smash]
      # @param directory [String]
      # @note parameter precedence:
      #   * Hook URL parameters
      #   * Payload parameters
      #   * Stacks file parameters
      #   * Service configuration parameters
      def load_stack_parameters(payload, directory)
        params = Smash.new
        stacks_file = load_stacks_file(payload, directory)
        s_namespace = determine_namespace(payload)
        template = payload.get(:data, :stacks, :template)
        params.deep_merge!(payload.fetch(:data, :webhook, :query, :stacks, :parameters, Smash.new))
        params.deep_merge!(payload.fetch(:data, :stacks, :parameters, Smash.new))
        params.deep_merge!(
          stacks_file.fetch(s_namespace, template, :parameters,
            stacks_file.fetch(:default, template, :parameters, Smash.new)
          )
        )
        params.deep_merge!(
          config.fetch(:parameter_overrides, s_namespace, template,
            config.fetch(:parameter_overrides, :default, template, Smash.new)
          )
        )
        params
      end

      # Parse the `.stacks` file if available
      #
      # @param payload [Smash]
      # @param directory [String] path to unpacked asset directory
      # @return [Smash]
      def load_stacks_file(payload, directory)
        stacks_path = File.join(directory, '.stacks')
        if(File.exists?(stacks_path))
          Bogo::Config.new(file_path).data
        else
          Smash.new
        end
      end

      # Perform stack action
      #
      # @param payload [Smash]
      # @param directory [String] directory to unpacked asset
      # @param action [Symbol, String] :create or :update
      # @return [TrueClass]
      def run_stack(payload, directory, action)
        unless([:create, :update].include?(action.to_sym))
          abort ArgumentError.new("Invalid action argument `#{action}`. Expecting `create` or `update`!")
        end
        args = build_stack_args(payload, directory)
        stack_name = payload.get(:data, :stacks, :name)
        Sfn::Command.const_get(action.to_s.capitalize).new(args, [stack_name]).execute!
        wait_for_complete(stacks_api.stacks.get(stack_name))
        true
      end

      # Wait for stack to reach a completion state
      #
      # @param stack [Miasma::Models::Orchestration::Stack]
      # @return [TrueClass]
      def wait_for_complete(stack)
        until(stack.state.to_s.donwcase.end_with?('complete') || stack.state.to_s.donwcase.end_with?('failed'))
          sleep(10)
          stack.reload
        end
        true
      end

      # Check if this payload is allowed to be processed based on
      # defined restrictions within the configuration
      #
      # @param payload [Smash]
      # @return [TrueClass, FalseClass]
      def allowed?(payload)
        !!determine_namespace(payload)
      end

      # Initialize provider if instructed via config
      #
      # @param payload [Smash]
      # @note this currently init's chef related items
      def init_provider(payload)
        if(config.get(:init, :chef, :validator) || config.get(:init, :chef, :encrypted_secret))
          bucket = stacks_api.api_for(:storage).buckets.get(config.get(:orchestration, :bucket_name))
          validator_name = name_for(payload, 'validator.pem')
          if(config.get(:init, :chef, :validator) && bucket.files.get(validator_name).nil?)
            file = bucket.files.build(:name => validator_name)
            file.body = OpenSSL::PKey::RSA.new(2048).export
            file.save
          end
          secret_name = name_for(payload, 'encrypted_data_bag_secret')
          if(config.get(:init, :chef, :encrypted_secret) && bucket.files.get(secret_name).nil?)
            file = bucket.files.build(:name => secret_name)
            file.body = SecureRandom.base64(2048)
            file.save
          end
        end
      end

      # Store stable asset in object store
      #
      # @param payload [Smash]
      def store_stable_asset(payload, directory)
        if(config.get(:init, :stable))
          ['.batali', 'Gemfile', 'Gemfile.lock'].each do |file|
            file_path = File.join(directory, file)
            if(File.exists?(file_path))
              debug "Removing file from infra directory: #{file}"
              FileUtils.rm(file_path)
            end
          end
          if(File.exists?(File.join(directory, 'batali.manifest')))
            debug 'Installing cookbooks from Batali manifest'
            Dir.chdir(directory) do
              Batali::Command::Install.new({}, []).execute!
            end
          end
          debug "Starting stable asset upload for #{payload[:id]}"
          bucket = stacks_api.api_for(:storage).buckets.get(config.get(:orchestration, :bucket_name))
          stable_name = name_for(payload, 'stable.zip')
          file = bucket.files.get(stable_name) || bucket.files.build(:name => stable_name)
          file.body = asset_store.pack(directory)
          file.save
          debug "Completed stable asset upload for #{payload[:id]}"
        end
      end

      # Provide prefixed key name for asset
      #
      # @param payload [Smash]
      # @param asset_name [String
      # @return [String]
      # @note this is currently a no-op and thus are shared across
      #   stacks. currently is stubbed for completion of template and
      #   interaction logic
      def name_for(payload, asset_name)
        File.join(determine_namespace(payload), asset_name)
        asset_name
      end

    end
  end
end
