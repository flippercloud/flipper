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
          def as_json(exclude_gates: false)
            result = {
              'key' => key,
              'state' => state.to_s,
            }

            unless exclude_gates
              gate_values = feature.adapter.get(self)
              result['gates'] = gates.map do |gate|
                Decorators::Gate.new(gate, gate_values[gate.key]).as_json
              end
            end

            result
          end
        end
      end
    end
  end
end
