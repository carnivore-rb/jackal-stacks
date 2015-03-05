require 'jackal-stacks'

module Jackal
  module Stacks
    # Stack destroyer
    class Wrecker < Callback

      include StackCommon

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
          payload.get(:data, :stacks, :wrecker)
        end
      end

      # Build or update stacks
      #
      # @param message [Carnivore::Message]
      def execute(message)
        failure_wrap(message) do |payload|
          s_name = stack_name(payload)
          stack = stacks_api.stacks.get(s_name)
          if(stack)
            info "Stack currently exists. Destroying. [#{stack.name}]"
            stack.destroy
            payload.set(:data, :stacks, :destroyed, true)
            job_completed(:stacks, payload, message)
          else
            error "Failed to locate requested stack for destruction [#{s_name}]"
            failed(payload, message, 'Requested stack does not exist')
          end
        end
      end

    end
  end
end
