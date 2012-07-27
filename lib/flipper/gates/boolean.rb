module Flipper
  module Gates
    class Boolean < Gate
      Key = :boolean

      def key
        @key ||= "#{@feature.name}.#{Key}"
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
        thing.is_a?(Flipper::Types::Boolean)
      end
    end
  end
end
