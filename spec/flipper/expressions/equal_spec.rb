RSpec.describe Flipper::Expressions::Equal do
  describe "#evaluate" do
    it "returns true when equal" do
      expression = described_class.new([
        Flipper.string("basic"),
        Flipper.string("basic"),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns true when properties equal" do
      expression = described_class.new([
        Flipper.property(:first),
        Flipper.property(:second),
      ])

      properties = {
        "first" => "foo",
        "second" => "foo",
      }
      expect(expression.evaluate(properties: properties)).to be(true)
    end

    it "works when nested" do
      expression = described_class.new([
        a = Flipper.boolean(true),
        b = Flipper.all(
          Flipper.property(:stinky).eq(true),
          Flipper.string("admin").eq(Flipper.property(:role))
        ),
      ])

      properties = {
        "stinky" => true,
        "role" => "admin",
      }

      expect(expression.evaluate(properties: properties)).to be(true)
    end

    it "returns false when not equal" do
      expression = described_class.new([
        Flipper.string("basic"),
        Flipper.string("plus"),
      ])

      expect(expression.evaluate).to be(false)
    end

    it "returns false when properties not equal" do
      expression = described_class.new([
        Flipper.property(:first),
        Flipper.property(:second),
      ])

      properties = {
        "first" => "foo",
        "second" => "bar",
      }
      expect(expression.evaluate(properties: properties)).to be(false)
    end

    it "returns false when value evaluates to nil" do
      expect(described_class.new([Flipper.number(nil), 1]).evaluate).to be(false)
      expect(described_class.new([1, Flipper.number(nil)]).evaluate).to be(false)
    end

    it "raises ArgumentError with no arguments" do
      expect { described_class.new([]).evaluate }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError with one argument" do
      expect { described_class.new([10]).evaluate }.to raise_error(ArgumentError)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([
        Flipper::Expressions::Property.new(["plan"]),
        Flipper.string("basic"),
      ])

      expect(expression.value).to eq({
        "Equal" => [
          {"Property" => ["plan"]},
          "basic",
        ],
      })
    end
  end
end
