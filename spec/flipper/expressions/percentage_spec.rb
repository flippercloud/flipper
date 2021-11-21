require 'helper'

RSpec.describe Flipper::Expressions::Percentage do
  describe "#evaluate" do
    it "returns true when string in percentage enabled" do
      expression = described_class.new([
        Flipper.value("User;1"),
        Flipper.value(42),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns true when string in fractional percentage enabled" do
      expression = described_class.new([
        Flipper.value("User;1"),
        Flipper.value(41.687),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns true when property evalutes to string that is percentage enabled" do
      expression = described_class.new([
        Flipper.property(:flipper_id),
        Flipper.value(42),
      ])

      properties = {
        "flipper_id" => "User;1",
      }
      expect(expression.evaluate(properties: properties)).to be(true)
    end

    it "returns false when string in percentage enabled" do
      expression = described_class.new([
        Flipper.value("User;1"),
        Flipper.value(0),
      ])

      expect(expression.evaluate).to be(false)
    end

    it "changes value based on feature_name so not all actors get all features first" do
      expression = described_class.new([
        Flipper.value("User;1"),
        Flipper.value(70),
      ])

      expect(expression.evaluate(feature_name: "a")).to be(true)
      expect(expression.evaluate(feature_name: "b")).to be(false)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([
        Flipper.value("User;1"),
        Flipper.value(10),
      ])

      expect(expression.value).to eq({
        "Percentage" => [
          {"Value" => ["User;1"]},
          {"Value" => [10]},
        ],
      })
    end
  end
end
