module Flipper
  module Toggles
    class Boolean < Toggle
      TruthMap = {
        true    => true,
        'true'  => true,
        'TRUE'  => true,
        'True'  => true,
        't'     => true,
        'T'     => true,
        '1'     => true,
        'on'    => true,
        'ON'    => true,
        1       => true,
        1.0     => true,
        false   => false,
        'false' => false,
        'FALSE' => false,
        'False' => false,
        'f'     => false,
        'F'     => false,
        '0'     => false,
        'off'   => false,
        'OFF'   => false,
        0       => false,
        0.0     => false,
        nil     => false,
      }

      def enable(thing)
        adapter.write adapter_key, thing.value
        true
      end

      def disable(thing)
        feature.gates.each do |gate|
          gate.adapter.delete gate.adapter_key
        end
        true
      end

      def value
        value = adapter.read(adapter_key)
        !!TruthMap[value]
      end

      def enabled?
        value
      end
    end
  end
end
