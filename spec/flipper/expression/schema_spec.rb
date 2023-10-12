require "json_schemer"
require "flipper-expressions-schema"

RSpec.describe Flipper::Expression::Schema do
  let(:schema) { Flipper::Expression::Schema.new }

  Flipper::Expression::Schema.examples.each do |name, examples|
    describe(name) do
      examples["valid"].each do |example|
        expression, context, result = example.values_at("expression", "context", "result")
        context&.transform_keys!(&:to_sym)

        describe expression.inspect do
          it "is valid" do
            errors = Flipper::Expression.build(expression).validate
            expect(errors.to_a).to eq([])
          end

          it "evaluates to #{result.inspect}#{" with context " + context.inspect if context}" do
            evaluated_result = Flipper::Expression.build(expression).evaluate(context || {})
            expected_schema = JSONSchemer.schema(result)
            expect(expected_schema.validate(evaluated_result).to_a).to eq([])
          end
        end
      end

      examples["invalid"].each do |example|
        context example.inspect do
          it "is invalid" do
            expect(schema.valid?(example)).not_to be(true)
          end

          it "should not evaluate" do
            expect { Flipper::Expression.build(example).evaluate }.to raise_error { |error|
              expect([ArgumentError, TypeError, NoMethodError]).to include(error.class)
            }
          end
        end
      end
    end
  end
end
