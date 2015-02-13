require 'jackal-stacks'

module Jackal
  module Stacks
    # Stack builder
    class Builder < Callback

      # Setup callback
      def setup(*_)
        require 'stringio'
        # Ensure we can build the API at startup
        stacks_api
      end

      # Determine validity of message
      #
      # @param message [Carnivore::Message]
      # @return [Truthy, Falsey]
      def valid?(message)
        super do |payload|
          payload.get(:data, :stacks, :template) &&
            payload.get(:data, :stacks, :asset) &&
            payload.get(:data, :stacks, :name) &&
            allowed?(payload)
        end
      end

      # @return [Miasma::Models::Orchestration]
      def stacks_api
        memoize(:stacks_api, :direct) do
          Miasma.api_for(
            config.fetch(
              :orchestration_api, Smash.new
            ).merge(
              :type => :orchestration
            )
          )
        end
      end

      # Build or update stacks
      #
      # @param message [Carnivore::Message]
      def execute(message)
        failure_wrap(message) do |payload|
          directory = unpack_asset(payload)
          stack = stacks_api.stacks.get(payload.get(:data, :stacks, :name))
          if(stack)
            info "Stack currently exists. Applying update [#{stack}]"
            payload.set(:data, :stacks, :updated, true)
            run_stack(payload, directory, :update)
          else
            info "Stack does not currently exist. Building new stack [#{payload.get(:data, :stacks, :name)}]"
            payload.set(:data, :stacks, :created, true)
            run_stack(payload, directory, :create)
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
          :base_directory => directory,
          :parameters => load_stack_parameters(payload, directory),
          :ui => Bogo::Ui.new(
            :defaults => true,
            :output_to => StringIO.new('')
          ),
          :interactive_parameters => false
        )
      end

      # Extract any custom parameters from asset store if available,
      # and merge any parameters provided via payload, and finally
      # merge any parameters provided via configuration
      #
      # @param payload [Smash]
      # @param directory [String]
      def load_stack_parameters(payload, directory)
        stack_name = payload.get(:data, :stacks, :name)
        params = Smash.new
        file_path = File.join(directory, '.stacks')
        if(File.exists?(file_path))
          stacks_file = Bogo::Config.new(file_path).data
          params.deep_merge!(stacks_file.fetch(stack_name, Smash.new))
        end
        params.deep_merge!(payload.fetch(:data, :stacks, :parameters, Smash.new))
        params.deep_merge!(
          config.fetch(:parameter_overrides, payload.get(:data, :stacks, :template),
            config.fetch(:parameter_overrides, :default, Smash.new)
          )
        )
        params
      end

      # Perform stack action
      #
      # @param payload [Smash]
      # @param directory [String] directory to unpacked asset
      # @param action [Symbol, String] :create or :update
      # @return [TrueClass]
      def run_stack(payload, directory, action)
        unless([:create, :upgrade].include?(action.to_sym))
          abort ArgumentError.new("Invalid action argument `#{action}`. Expecting `create` or `upgrade`!")
        end
        args = build_stack_args(payload, directory)
        stack_name = payload.get(:data, :stacks, :name)
        Sfn::Command.const_get(action.to_s.capitalize).new(args, stack_name).execute!
        true
      end

      # Check if this payload is allowed to be processed based on
      # defined restrictions within the configuration
      #
      # @param payload [Smash]
      # @return [TrueClass, FalseClass]
      def allowed?(payload)
        if(config.get(:restrictions, :reference))
          restrict_to = [config.get(:restrictions, :reference)].flatten.compact
          !!payload.get(:data, :code_fetcher, :info, :reference).to_s.split('/').detect do |part|
            restrict_to.include?(part)
          end
        else
          true
        end
      end

    end
  end
end
