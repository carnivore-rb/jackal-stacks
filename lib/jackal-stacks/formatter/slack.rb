require 'jackal-stacks'

module Jackal
  module Stacks
    module Formatter
      # Format result for slack notification
      class Slack < Jackal::Formatter

        # Source service
        SOURCE = 'stacks'
        # Destination service
        DESTINATION = 'slack'

        NOTIFY_ON = %w(created updated destroyed)

        # Format payload
        #
        # @param payload [Smash]
        def format(payload)
          if(payload.get(:data, :stacks))
            unless((notify = payload.fetch(:data, :stacks, {}).keys & NOTIFY_ON).empty?)
              msgs = payload.fetch(:data, :slack, :messages, [])
              msgs << Smash.new(
                :description => "Stacks result: #{notify.first}",
                :message => [
                  "Stack has been #{notify.first} [name: #{payload.get(:data, :stacks, :name)}]",
                  "* Template: #{payload.get(:data, :stacks, :template)}",
                  "* Repository: #{payload.get(:data, :code_fetcher, :info, :owner)}/#{payload.get(:data, :code_fetcher, :info, :name)}",
                  "* Reference: #{payload.get(:data, :code_fetcher, :info, :reference)}",
                  "* SHA: #{payload.get(:data, :code_fetcher, :info, :commit_sha)}"
                ].join("\n"),
                :color => :good
              )
              payload.set(:data, :slack, :messages, msgs)
            end
          end
        end

      end

    end
  end
end
