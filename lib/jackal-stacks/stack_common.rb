require 'jackal-stacks'

module Jackal
  module Stacks
    module StackCommon

      # @return [Miasma::Models::Orchestration]
      def stacks_api
        memoize(:stacks_api, api_config.to_smash.checksum) do
          Miasma.api(api_config)
        end
      end

      # @return [Hash] API connection configuration
      def api_config
        config.fetch(:orchestration, :api, Smash.new).merge(
          :type => :orchestration
        )
      end

      # Determine namespace key to use for accessing parameters
      #
      # @param payload [Smash]
      # @return [String]
      # @note if not match found, `default` will return
      def determine_namespace(payload)
        config.fetch(:mappings, Smash.new).map do |ns, glob|
          ns if File.fnmatch?(glob, payload.get(:data, :stacks, :reference).to_s)
        end.compact.first
      end

      # Generate stack name based on payload
      #
      # @param payload [Smash]
      # @return [String] stack name
      def stack_name(payload)
        s_namespace = determine_namespace(payload)
        s_project = payload.fetch(:data, :stacks, :project, SecureRandom.urlsafe_base64)
        [
          s_namespace,
          s_project,
          payload.get(:data, :stacks, :template).sub(/\.[a-z]+$/, '')
        ].compact.join('-').gsub(/[^A-Za-z0-9\-]/, '-')
      end

    end
  end
end
