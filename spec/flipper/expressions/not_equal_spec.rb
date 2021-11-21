require 'helper'

RSpec.describe Flipper::Expressions::NotEqual do
  describe "#evaluate" do
    it "returns true when not equal" do
      expression = described_class.new([
        Flipper.value("basic"),
        Flipper.value("plus"),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns true when properties not equal" do
      expression = described_class.new([
        Flipper.property(:first),
        Flipper.property(:second),
      ])

      properties = {
        "first" => "foo",
        "second" => "bar",
      }
      expect(expression.evaluate(properties: properties)).to be(true)
    end

    it "returns false when equal" do
      expression = described_class.new([
        Flipper.value("basic"),
        Flipper.value("basic"),
      ])

      expect(expression.evaluate).to be(false)
    end

    it "returns false when properties are equal" do
      expression = described_class.new([
        Flipper.property(:first),
        Flipper.property(:second),
      ])

      properties = {
        "first" => "foo",
        "second" => "foo",
      }
      expect(expression.evaluate(properties: properties)).to be(false)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([
        Flipper.value(20),
        Flipper.value(10),
      ])

      expect(expression.value).to eq({
        "NotEqual" => [
          {"Value" => [20]},
          {"Value" => [10]},
        ],
      })
    end
  end
end
