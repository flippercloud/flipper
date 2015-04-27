require 'delegate'
require 'flipper/ui/decorators/gate'
require 'flipper/ui/util'

module Flipper
  module UI
    module Decorators
      class Feature < SimpleDelegator
        include Comparable

        # Public: The feature being decorated.
        alias_method :feature, :__getobj__

        # Public: Returns name titleized.
        def pretty_name
          @pretty_name ||= Util.titleize(name)
        end

        # Public: Returns instance as hash that is ready to be json dumped.
        def as_json
          gate_values = feature.gate_values
          {
            'id' => name.to_s,
            'name' => pretty_name,
            'state' => state.to_s,
            'gates' => gates.map { |gate|
              Decorators::Gate.new(gate, gate_values[gate.key]).as_json
            },
          }
        end

        def color_class
          case feature.state
          when :on
            "text-open"
          when :off
            "text-closed"
          when :conditional
            "text-pending"
          end
        end

        def pretty_enabled_gate_names
          enabled_gates.map { |gate| Util.titleize(gate.key) }.sort.join(', ')
        end

        StateSortMap = {
          :on => 1,
          :conditional => 2,
          :off => 3,
        }

        def <=>(other)
          if state == other.state
            key <=> other.key
          else
            StateSortMap[state] <=> StateSortMap[other.state]
          end
        end
      end
    end
  end
end
