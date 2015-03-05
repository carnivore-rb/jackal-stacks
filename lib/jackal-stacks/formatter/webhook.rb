require 'jackal-stacks'

module Jackal
  module Stacks
    module Formatter
      # Format webhook data for stacks
      class Webhook < Jackal::Formatter

        SOURCE = 'webhook'
        DESTINATION = 'stacks'

        # Format payload
        #
        # @param payload [Smash]
        def format(payload)
          if(payload.get(:data, :webhook, :query, :template))
            payload.set(:data, :stacks, :template,
              payload.get(:data, :webhook, :query, :template)
            )
          end
        end

      end

    end
  end
end
