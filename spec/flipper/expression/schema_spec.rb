require "flipper/expression"
require "json_schemer"

RSpec.describe Flipper::Expression::Schema do
  schema = Flipper::Expression::Schema.instance
  examples_glob = File.expand_path("../../fixtures/expressions/examples/*.json", __dir__)

  describe ".schemas" do
    it "loads the vendored schema files" do
      expect(described_class.schemas).to include("schema.json", "FeatureEnabled.schema.json")
    end
  end

  # Shared examples vendored from flippercloud/expressions so Ruby and JS test the
  # exact same valid/invalid cases. Re-vendor with `rake expressions:vendor`.
  Dir[examples_glob].sort.each do |path|
    name = File.basename(path, ".json")
    examples = Flipper::Typecast.from_json(File.read(path))

    describe name do
      Array(examples["valid"]).each do |example|
        expression = example["expression"]
        result = example["result"]
        context = example["context"]&.transform_keys(&:to_sym)

        describe expression.inspect do
          it "is valid" do
            built = Flipper::Expression.build(expression)
            expect(built.validate.to_a).to eq([])
            expect(built.valid?).to be(true)
          end

          if result
            it "evaluates to a result matching #{result.inspect}" do
              evaluated = Flipper::Expression.build(expression).evaluate(context || {})
              # Coerce non-JSON-native values (Time) so the result schema can match.
              value = evaluated.is_a?(::Time) ? evaluated.iso8601 : evaluated
              expect(JSONSchemer.schema(result).valid?(value)).to be(true)
            end
          end
        end
      end

      # Mirrors the JS suite in flippercloud/expressions: an invalid example is
      # one the schema rejects. (Runtime evaluation leniency is a separate concern;
      # validation is the enforcement point, run before an expression is saved.)
      Array(examples["invalid"]).each do |example|
        it "rejects #{example.inspect}" do
          expect(schema.valid?(example)).to be(false)
        end
      end
    end
  end
end
