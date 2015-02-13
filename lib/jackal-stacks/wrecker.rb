require 'jackal-stacks'

module Jackal
  module Stacks
    # Stack destroyer
    class Wrecker < Callback

      # Setup callback
      def setup(*_)
        stacks_api
      end

      # Determine validity of message
      #
      # @param message [Carnivore::Message]
      # @return [Truthy, Falsey]
      def valid?(message)
        super do |payload|
          payload.get(:data, :stacks, :wrecker) &&
            payload.get(:data, :stacks, :name)
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
          stack = stacks_api.stacks.get(payload.get(:data, :stacks, :name))
          if(stack)
            info "Stack currently exists. Destroying. [#{stack}]"
            stack.destroy
            payload.set(:data, :stacks, :destroyed, true)
            job_completed(:stacks, payload, message)
          else
            error "Failed to locate requested stack for destruction [#{payload.get(:data, :stacks, :name)}]"
            failed(payload, message, 'Requested stack does not exist')
          end
        end
      end

    end
  end
end
