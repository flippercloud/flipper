require 'zlib'

module Flipper
  module Gates
    class PercentageOfActors < Gate
      Key = :perc_actors

      def type_key
        Key
      end

      def open?(thing)
        percentage = toggle.value.to_i

        if Types::Actor.wrappable?(thing)
          actor = Types::Actor.wrap(thing)
          Zlib.crc32(actor.value) % 100 < percentage
        else
          false
        end
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::PercentageOfActors)
      end
    end
  end
end
