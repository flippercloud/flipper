require 'helper'

RSpec.describe Flipper::Expressions::GreaterThanOrEqualTo do
  describe "#evaluate" do
    it "returns true when equal" do
      expression = described_class.new([2, 2])
      expect(expression.evaluate).to be(true)
    end

    it "returns true when equal with args that need evaluation" do
      expression = described_class.new([
        Flipper.value(2),
        Flipper.value(2),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns true when greater" do
      expression = described_class.new([2, 1])
      expect(expression.evaluate).to be(true)
    end

    it "returns false when less" do
      expression = described_class.new([1, 2])
      expect(expression.evaluate).to be(false)
    end

    it "returns false with no arguments" do
      expression = described_class.new([])
      expect(expression.evaluate).to be(false)
    end

    it "returns false with one argument" do
      expression = described_class.new([10])
      expect(expression.evaluate).to be(false)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([
        Flipper.value(20),
        Flipper.value(10),
      ])

      expect(expression.value).to eq({
        "GreaterThanOrEqualTo" => [
          {"Value" => [20]},
          {"Value" => [10]},
        ],
      })
    end
  end
end
