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

        attr_accessor :description

        # Public: Returns name titleized.
        def pretty_name
          @pretty_name ||= Util.titleize(name)
        end

        def color_class
          case feature.state
          when :on
            'text-success'
          when :off
            'text-danger'
          when :conditional
            'text-warning'
          end
        end

        def pretty_enabled_gate_names
          enabled_gates.map { |gate| Util.titleize(gate.key) }.sort.join(', ')
        end

        StateSortMap = {
          on: 1,
          conditional: 2,
          off: 3,
        }.freeze

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
