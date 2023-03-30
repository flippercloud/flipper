require 'json_schemer'

RSpec.describe Flipper::Expressions do
  EXPRESSION_JS_PATH = File.expand_path('../../packages/expressions', __dir__)

  SCHEMAS = Hash[Dir.glob(File.join(EXPRESSION_JS_PATH, 'schemas/*.json')).map do |path|
    [File.basename(path), JSON.parse(File.read(path))]
  end]

  EXAMPLES = Dir.glob(File.join(EXPRESSION_JS_PATH, 'test/examples/*.json'))

  let(:schema) do
    JSONSchemer.schema(SCHEMAS["schema.json"], ref_resolver: lambda {|url|
      SCHEMAS[File.basename(url.path)]
    })
  end

  EXAMPLES.each do |path|
    describe(File.basename(path, '.json')) do
      examples = JSON.parse(File.read(path))
      examples["valid"].each do |example|
        expression, context, result  = example.values_at("expression", "context", "result")
        context&.transform_keys!(&:to_sym)

        describe expression.inspect do
          it "is valid" do
            expect(schema.validate(expression).to_a).to eq([])
          end

          it "evaluates to #{result.inspect}#{ " with context " + context.inspect if context}" do
            evaluated_result = Flipper::Expression.build(expression).evaluate(context || {}   )
            expected_schema = JSONSchemer.schema(result, before_property_validation: lambda {|data, property, property_schema, _parent|
              puts "BEFORE: #{[data, property, property_schema, _parent].inspect}"
            })
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
              expect([ArgumentError, TypeError]).to include(error.class)
            }
          end
        end
      end
    end
  end
end
