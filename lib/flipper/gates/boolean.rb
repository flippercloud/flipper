module Flipper
  module Gates
    class Boolean < Gate
      Key = :boolean

      def name
        :boolean
      end

      def type_key
        Key
      end

      def toggle_class
        Toggles::Boolean
      end

      def open?(thing)
        instrument(:open, thing) {
          value = toggle.value

          if value.nil?
            false
          else
            throw :short_circuit, !!value
          end
        }
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Boolean)
      end
    end
  end
end
