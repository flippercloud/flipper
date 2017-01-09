require 'delegate'
require 'flipper/api/v1/decorators/gate'

module Flipper
  module Api
    module V1
      module Decorators
        class Feature < SimpleDelegator
          # Public: The feature being decorated.
          alias_method :feature, :__getobj__

          # Public: Returns instance as hash that is ready to be json dumped.
          def as_json
            gate_values = feature.gate_values
            {
              'key' => key,
              'state' => state.to_s,
              'gates' => gates.map do |gate|
                Decorators::Gate.new(gate, gate_values[gate.key]).as_json
              end,
            }
          end
        end
      end
    end
  end
end
