module Flipper
  module Api
    module V1
      module Decorators
        class Gate
          def initialize(gate, value = nil)
            @gate = gate
            @value = value
          end

          def as_json(exclude_name: false)
            as_json = {
              'key' => @gate.key.to_s,
              'value' => value_as_json,
            }
            as_json['name'] = @gate.name.to_s unless exclude_name
            as_json
          end

          private

          # Set of types that should be represented as Array in JSON.
          JSON_ARRAY_TYPES = Set[:set].freeze

          # json doesn't like sets
          def value_as_json
            JSON_ARRAY_TYPES.include?(@gate.data_type) ? @value.to_a : @value
          end
        end
      end
    end
  end
end
