require 'jackal-stacks'

module Jackal
  module Stacks
    module Formatter
      # Format github data for stacks
      class Github < Jackal::Formatter

        # Source service
        SOURCE = :github
        # Destination service
        DESTINATION = :stacks

        # Valid github events
        VALID_EVENTS = %w(create delete push)

        # Format payload
        #
        # @param payload [Smash]
        def format(payload)
          if(VALID_EVENTS.include?(payload.get(:data, :github, :event)))
            if(payload.get(:data, :github, :query, :template))
              payload.set(:data, :stacks, :template,
                payload.get(:data, :github, :query, :template)
              )
            end
            if(payload.get(:data, :github, :event) == 'delete')
              payload.set(:data, :stacks, :wrecker, true)
            else
              payload.set(:data, :stacks, :builder, true)
            end
          end
        end

      end

    end
  end
end
