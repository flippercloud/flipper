RSpec.describe Flipper::UI::Decorators::Feature do
  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }
  let(:flipper) { build_flipper }
  let(:feature) { flipper[:some_awesome_feature] }

  subject do
    described_class.new(feature)
  end

  describe '#initialize' do
    it 'sets the feature' do
      expect(subject.feature).to be(feature)
    end
  end

  describe '#pretty_name' do
    it 'capitalizes each word separated by underscores' do
      expect(subject.pretty_name).to eq('Some Awesome Feature')
    end
  end

  describe '#<=>' do
    let(:on) do
      flipper.enable(:on_a)
      described_class.new(flipper[:on_a])
    end

    let(:on_b) do
      flipper.enable(:on_b)
      described_class.new(flipper[:on_b])
    end

    let(:conditional) do
      flipper.enable_percentage_of_time :conditional_a, 5
      described_class.new(flipper[:conditional_a])
    end

    let(:off) do
      described_class.new(flipper[:off_a])
    end

    it 'sorts :on before :conditional' do
      expect((on <=> conditional)).to be(-1)
    end

    it 'sorts :on before :off' do
      expect((on <=> off)).to be(-1)
    end

    it 'sorts :conditional before :off' do
      expect((conditional <=> off)).to be(-1)
    end

    it 'sorts on key for identical states' do
      expect((on <=> on_b)).to be(-1)
    end
  end

  describe '#has_expression?' do
    it 'returns false when no expression is set' do
      expect(subject.has_expression?).to be(false)
    end

    it 'returns true when expression is set' do
      expression = Flipper.property(:plan).eq("basic")
      feature.enable_expression(expression)
      expect(subject.has_expression?).to be(true)
    end

    it 'returns false when expression value is empty' do
      allow(feature).to receive(:expression_value).and_return({})
      expect(subject.has_expression?).to be(false)
    end
  end

  describe '#expression_summary' do
    it 'returns "none" when no expression is set' do
      expect(subject.expression_summary).to eq("none")
    end

    it 'returns formatted summary for simple comparison' do
      expression = Flipper.property(:plan).eq("basic")
      feature.enable_expression(expression)
      expect(subject.expression_summary).to eq('plan = "basic"')
    end

    it 'returns formatted summary for numeric comparison' do
      expression = Flipper.property(:age).gte(21)
      feature.enable_expression(expression)
      expect(subject.expression_summary).to eq("age ≥ 21")
    end

    it 'returns "Any of 0 conditions" for empty Any expression' do
      allow(feature).to receive(:expression_value).and_return({"Any" => []})
      expect(subject.expression_summary).to eq("Any of 0 conditions")
    end
  end

  describe '#expression_description' do
    it 'returns "No expression set" when no expression is set' do
      expect(subject.expression_description).to eq("No expression set")
    end

    it 'returns verbose description for simple comparison' do
      expression = Flipper.property(:plan).eq("basic")
      feature.enable_expression(expression)
      expect(subject.expression_description).to eq('plan equals "basic"')
    end

    it 'returns verbose description for numeric comparison' do
      expression = Flipper.property(:age).lt(18)
      feature.enable_expression(expression)
      expect(subject.expression_description).to eq("age is less than 18")
    end
  end

  describe '#gates_in_words' do
    it 'includes expression in the summary when expression is set' do
      expression = Flipper.property(:plan).eq("basic")
      feature.enable_expression(expression)
      expect(subject.gates_in_words).to include('actors with plan = "basic"')
    end

    it 'does not include expression when no expression is set' do
      expect(subject.gates_in_words).not_to include('expression')
    end
  end

  describe '#expression_state' do
    it 'returns :off when no expression is set' do
      expect(subject.expression_state).to eq(:off)
    end

    it 'returns :conditional when expression is set' do
      expression = Flipper.property(:plan).eq("basic")
      feature.enable_expression(expression)
      expect(subject.expression_state).to eq(:conditional)
    end
  end

  describe 'sorting with expressions' do
    let(:expression_feature) do
      flipper.enable_expression :expression_a, Flipper.property(:plan).eq("basic")
      described_class.new(flipper[:expression_a])
    end

    let(:boolean_feature) do
      flipper.enable :boolean_a
      described_class.new(flipper[:boolean_a])
    end

    let(:percentage_feature) do
      flipper.enable_percentage_of_time :percentage_a, 50
      described_class.new(flipper[:percentage_a])
    end

    let(:off_feature) do
      described_class.new(flipper[:off_a])
    end

    it 'sorts boolean before expression' do
      expect((boolean_feature <=> expression_feature)).to be(-1)
    end

    it 'sorts expression before percentage' do
      expect((expression_feature <=> percentage_feature)).to be(-1)
    end

    it 'sorts expression before off' do
      expect((expression_feature <=> off_feature)).to be(-1)
    end
  end

  describe '#expression_form_values' do
    context 'when no expression is set' do
      it 'returns default property type' do
        expect(subject.expression_form_values).to eq({ type: "property" })
      end
    end

    context 'when simple expression is set' do
      it 'returns form values for Equal operator' do
        expression = Flipper.property(:user_id).eq("123")
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "property",
          property: "user_id",
          operator: "eq",
          value: "123"
        })
      end

      it 'returns form values for NotEqual operator' do
        expression = Flipper.property(:plan).neq("premium")
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "property",
          property: "plan",
          operator: "ne",
          value: "premium"
        })
      end

      it 'returns form values for GreaterThan operator' do
        expression = Flipper.property(:age).gt(21)
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "property",
          property: "age",
          operator: "gt",
          value: "21"
        })
      end

      it 'returns form values for GreaterThanOrEqualTo operator' do
        expression = Flipper.property(:score).gte(100)
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "property",
          property: "score",
          operator: "gte",
          value: "100"
        })
      end

      it 'returns form values for LessThan operator' do
        expression = Flipper.property(:count).lt(5)
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "property",
          property: "count",
          operator: "lt",
          value: "5"
        })
      end

      it 'returns form values for LessThanOrEqualTo operator' do
        expression = Flipper.property(:limit).lte(10)
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "property",
          property: "limit",
          operator: "lte",
          value: "10"
        })
      end

      it 'returns form values for boolean true value' do
        expression = Flipper.property(:premium).eq(true)
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "property",
          property: "premium",
          operator: "eq",
          value: "true"
        })
      end

      it 'returns form values for boolean false value' do
        expression = Flipper.property(:premium).eq(false)
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "property",
          property: "premium",
          operator: "eq",
          value: "false"
        })
      end

      it 'returns form values for float value' do
        expression = Flipper.property(:rating).gt(4.5)
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "property",
          property: "rating",
          operator: "gt",
          value: "4.5"
        })
      end
    end

    context 'when complex expression is set' do
      it 'returns complex form data for Any expression' do
        expression = Flipper.any([
          Flipper.property(:user_id).eq("123"),
          Flipper.property(:premium).eq(true)
        ])
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "any",
          expressions: [
            { property: "user_id", operator: "eq", value: "123" },
            { property: "premium", operator: "eq", value: "true" }
          ]
        })
      end

      it 'returns complex form data for All expression' do
        expression = Flipper.all([
          Flipper.property(:age).gte(21),
          Flipper.property(:country).eq("US")
        ])
        feature.enable_expression(expression)
        expect(subject.expression_form_values).to eq({
          type: "all",
          expressions: [
            { property: "age", operator: "gte", value: "21" },
            { property: "country", operator: "eq", value: "US" }
          ]
        })
      end
    end

    context 'when expression has invalid format' do
      it 'returns default property type for non-hash expression value' do
        allow(feature).to receive(:expression_value).and_return("invalid")
        expect(subject.expression_form_values).to eq({ type: "property" })
      end

      it 'returns default property type for malformed expression structure' do
        allow(feature).to receive(:expression_value).and_return({
          "Equal" => ["not_array_of_two"]
        })
        expect(subject.expression_form_values).to eq({ type: "property" })
      end

      it 'returns default property type for expression without Property key' do
        allow(feature).to receive(:expression_value).and_return({
          "Equal" => [
            { "NotProperty" => ["plan"] },
            "basic"
          ]
        })
        expect(subject.expression_form_values).to eq({ type: "property" })
      end
    end

    context 'when expression has unknown operator' do
      it 'returns eq as default operator' do
        allow(feature).to receive(:expression_value).and_return({
          "UnknownOperator" => [
            { "Property" => ["plan"] },
            "basic"
          ]
        })
        expect(subject.expression_form_values).to eq({
          type: "property",
          property: "plan",
          operator: "eq",
          value: "basic"
        })
      end
    end
  end
end
