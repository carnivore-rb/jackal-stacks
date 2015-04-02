require 'jackal-stacks'

module Jackal
  module Stacks
    module Formatter
      # Format code fetcher data for stacks
      class CodeFetcher < Jackal::Formatter

        SOURCE = 'code_fetcher'
        DESTINATION = 'stacks'

        # Format payload
        #
        # @param payload [Smash]
        def format(payload)
          if(payload.get(:data, :code_fetcher))
            payload.set(:data, :stacks, :asset,
              payload.get(:data, :code_fetcher, :asset)
            )
            payload.set(:data, :stacks, :reference,
              payload.get(:data, :code_fetcher, :info, :reference)
            )
            payload.set(:data, :stacks, :project,
              [payload.get(:data, :code_fetcher, :info, :owner),
                payload.get(:data, :code_fetcher, :info, :name)].join('_')
            )
          end
        end

      end

    end
  end
end
