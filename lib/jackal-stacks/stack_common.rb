require 'jackal-stacks'

module Jackal
  module Stacks
    module StackCommon

      # @return [Miasma::Models::Orchestration]
      def stacks_api
        memoize(:stacks_api, :direct) do
          Miasma.api(
            config.fetch(
              :orchestration, :api, Smash.new
            ).merge(
              :type => :orchestration
            )
          )
        end
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
        "#{s_namespace}-#{payload.get(:data, :stacks, :template).sub(/\.[a-z]+$/, '').gsub(/[^A-Za-z0-9\-]/, '-')}"
      end

    end
  end
end
