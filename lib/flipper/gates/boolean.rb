module Flipper
  module Gates
    class Boolean < Gate
      def key
        @key ||= "#{@feature.name}.boolean"
      end

      def toggle
        @toggle ||= Toggles::Value.new(@feature.adapter, key)
      end

      def match?(actor)
        value = toggle.value

        if value.nil?
          false
        else
          throw :short_circuit, !!value
        end
      end

      def protects?(thing)
        thing.is_a?(Flipper::Boolean)
      end
    end
  end
end
