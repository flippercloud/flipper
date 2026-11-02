RSpec.describe Flipper::Gates::Expression do
  let(:feature_name) { :search }

  subject do
    described_class.new
  end

  def context(expression, properties: {})
    Flipper::FeatureCheckContext.new(
      feature_name: feature_name,
      values: Flipper::GateValues.new(expression: expression),
      actors: [Flipper::Types::Actor.new(Flipper::Actor.new(1, properties))]
    )
  end

  describe '#enabled?' do
    context 'for nil value' do
      it 'returns false' do
        expect(subject.enabled?(nil)).to eq(false)
      end
    end

    context 'for empty value' do
      it 'returns false' do
        expect(subject.enabled?({})).to eq(false)
      end
    end

    context "for not empty value" do
      it 'returns true' do
        expect(subject.enabled?({"Boolean" => [true]})).to eq(true)
      end
    end
  end

  describe '#open?' do
    context 'for expression that evaluates to true' do
      it 'returns true' do
        expression = Flipper.boolean(true).eq(true)
        expect(subject.open?(context(expression.value))).to be(true)
      end
    end

    context 'for a time expression on a property the actor does not have' do
      it 'returns false' do
        time = Flipper.time(Flipper.property(:trial_ends_at))
        expression = Flipper.now.gt(time)
        expect(subject.open?(context(expression.value))).to be(false)
      end
    end

    context 'for expressions on property values of the wrong type' do
      [
        ["a hash as a number", { "GreaterThan" => [{ "Number" => [{ "Property" => ["x"] }] }, 1] }, { "x" => { "a" => 1 } }],
        ["an array as a percentage", { "GreaterThan" => [{ "Percentage" => [{ "Property" => ["x"] }] }, 1] }, { "x" => [1] }],
        ["an array as a percentage under a limit", { "LessThan" => [{ "Percentage" => [{ "Property" => ["x"] }] }, 1] }, { "x" => [1] }],
        ["a missing percentage", { "PercentageOfActors" => [{ "Property" => ["flipper_id"] }, { "Property" => ["x"] }] }, {}],
        ["a string percentage", { "PercentageOfActors" => [{ "Property" => ["flipper_id"] }, { "Property" => ["x"] }] }, { "x" => "50" }],
        ["a string as a random max", { "LessThan" => [{ "Random" => [{ "Property" => ["x"] }] }, 1] }, { "x" => "abc" }],
        ["infinity as a time", { "GreaterThan" => [{ "Now" => [] }, { "Time" => [{ "Property" => ["x"] }] }] }, { "x" => Float::INFINITY }],
      ].each do |description, expression, properties|
        it "returns false for #{description}" do
          expect(subject.open?(context(expression, properties: properties))).to be(false)
        end
      end
    end

    context 'for expression that evaluates to false' do
      it 'returns false' do
        expression = Flipper.boolean(true).eq(false)
        expect(subject.open?(context(expression.value))).to be(false)
      end
    end

    context 'for properties that have string keys' do
      it 'returns true when expression evalutes to true' do
        expression = Flipper.property(:type).eq("User")
        context = context(expression.value, properties: {"type" => "User"})
        expect(subject.open?(context)).to be(true)
      end

      it 'returns false when expression evaluates to false' do
        expression = Flipper.property(:type).eq("User")
        context = context(expression.value, properties: {"type" => "Org"})
        expect(subject.open?(context)).to be(false)
      end
    end

    context 'for actor in context' do
      it 'passes actor to expression context' do
        actor = Flipper::Actor.new("User;1", {type: "User"})
        wrapped_actor = Flipper::Types::Actor.new(actor)
        expression = Flipper.property(:flipper_id).eq("User;1")
        ctx = Flipper::FeatureCheckContext.new(
          feature_name: feature_name,
          values: Flipper::GateValues.new(expression: expression.value),
          actors: [wrapped_actor]
        )
        expect(subject.open?(ctx)).to be(true)
      end

      it 'passes nil actor when no actors provided' do
        expression = Flipper.boolean(true).eq(true)
        ctx = Flipper::FeatureCheckContext.new(
          feature_name: feature_name,
          values: Flipper::GateValues.new(expression: expression.value),
          actors: nil
        )
        expect(subject.open?(ctx)).to be(true)
      end
    end

    context 'for properties that have symbol keys' do
      it 'returns true when expression evalutes to true' do
        expression = Flipper.property(:type).eq("User")
        context = context(expression.value, properties: {type: "User"})
        expect(subject.open?(context)).to be(true)
      end

      it 'returns false when expression evaluates to false' do
        expression = Flipper.property(:type).eq("User")
        context = context(expression.value, properties: {type: "Org"})
        expect(subject.open?(context)).to be(false)
      end
    end

    context 'for time-based expressions' do
      it 'enables when now is past a scheduled epoch' do
        past_epoch = Time.now.to_i - 86_400
        expression = Flipper.now.gte(Flipper.time(past_epoch))
        expect(subject.open?(context(expression.value))).to be(true)
      end

      it 'does not enable when now is before a future epoch' do
        future_epoch = Time.now.to_i + 86_400
        expression = Flipper.now.gte(Flipper.time(future_epoch))
        expect(subject.open?(context(expression.value))).to be(false)
      end

      it 'enables when now is past a scheduled datetime' do
        past_time = (Time.now.utc - 86_400).iso8601
        expression = Flipper.now.gte(Flipper.time(past_time))
        expect(subject.open?(context(expression.value))).to be(true)
      end

      it 'does not enable when now is before a future datetime' do
        future_time = (Time.now.utc + 86_400).iso8601
        expression = Flipper.now.gte(Flipper.time(future_time))
        expect(subject.open?(context(expression.value))).to be(false)
      end

      it 'enables expiring features with lt' do
        future_time = (Time.now.utc + 86_400).iso8601
        expression = Flipper.now.lt(Flipper.time(future_time))
        expect(subject.open?(context(expression.value))).to be(true)
      end

      it 'disables expired features with lt' do
        past_time = (Time.now.utc - 86_400).iso8601
        expression = Flipper.now.lt(Flipper.time(past_time))
        expect(subject.open?(context(expression.value))).to be(false)
      end

      it 'enables within a time window using all' do
        start_time = (Time.now.utc - 86_400).iso8601
        end_time = (Time.now.utc + 86_400).iso8601
        expression = Flipper.all(
          Flipper.now.gte(Flipper.time(start_time)),
          Flipper.now.lt(Flipper.time(end_time))
        )
        expect(subject.open?(context(expression.value))).to be(true)
      end

      it 'does not enable outside a time window' do
        start_time = (Time.now.utc + 86_400).iso8601
        end_time = (Time.now.utc + 172_800).iso8601
        expression = Flipper.all(
          Flipper.now.gte(Flipper.time(start_time)),
          Flipper.now.lt(Flipper.time(end_time))
        )
        expect(subject.open?(context(expression.value))).to be(false)
      end
    end
  end

  describe '#protects?' do
    it 'returns true for Flipper::Expression' do
      expression = Flipper.number(20).eq(20)
      expect(subject.protects?(expression)).to be(true)
    end

    it 'returns true for Hash' do
      expression = Flipper.number(20).eq(20)
      expect(subject.protects?(expression.value)).to be(true)
    end

    it 'returns false for other things' do
      expect(subject.protects?(false)).to be(false)
    end
  end

  describe '#wrap' do
    it 'returns self for Flipper::Expression' do
      expression = Flipper.number(20).eq(20)
      expect(subject.wrap(expression)).to be(expression)
    end

    it 'returns Flipper::Expression for Hash' do
      expression = Flipper.number(20).eq(20)
      expect(subject.wrap(expression.value)).to be_instance_of(Flipper::Expression)
      expect(subject.wrap(expression.value)).to eq(expression)
    end
  end
end
