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
          unless((notify = payload.get(:data, :stacks, {}).keys & NOTIFY_ON).empty?)
            msgs = payload.fetch(:data, :slack, :messages, [])
            msgs << Smash.new(
              :description => "Stacks result: #{notify.first}",
              :message => "Stack has been #{notify.first} [name: #{payload.get(:data, :stacks, :name)}]",
              :color => :good
            )
          end
        end

      end

    end
  end
end
