module Flipper
  module Api
    module V1
      module Decorators
        class Gate < SimpleDelegator
          # Public the gate being decorated
          alias_method :gate, :__getobj__

          # Public: the value for the gate from the adapter.
          attr_reader :value

          def initialize(gate, value = nil)
            super gate
            @value = value
          end

          def as_json
            {
              'key' => gate.key.to_s,
              'name' => gate.name.to_s,
              'value' => value_as_json,
            }
          end

          private

          # Set of types that should be represented as Array in JSON.
          JSON_ARRAY_TYPES = Set[:set, :json].freeze

          # json doesn't like sets
          def value_as_json
            JSON_ARRAY_TYPES.include?(data_type) ? value.to_a : value
          end
        end
      end
    end
  end
end
