module Flipper
  module Gates
    class Actor < Gate
      Key = :actors

      def name
        :actor
      end

      def key
        Key
      end

      def toggle_class
        Toggles::Set
      end

      def open?(thing)
        instrument(:open, thing) {
          if thing.nil?
            false
          else
            if Types::Actor.wrappable?(thing)
              actor = Types::Actor.wrap(thing)
              ids.include?(actor.value)
            else
              false
            end
          end
        }
      end

      def ids
        toggle.value
      end

      def protects?(thing)
        Types::Actor.wrappable?(thing)
      end

      def enable(thing)
        toggle.enable Types::Actor.wrap(thing)
      end

      def disable(thing)
        toggle.disable Types::Actor.wrap(thing)
      end
    end
  end
end
