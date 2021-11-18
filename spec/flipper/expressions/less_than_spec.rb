require 'helper'

RSpec.describe Flipper::Expressions::LessThan do
  describe "#evaluate" do
    it "returns false when equal" do
      expression = described_class.new([
        Flipper::Expressions::Value.new(2),
        Flipper::Expressions::Value.new(2),
      ])

      expect(expression.evaluate).to be(false)
    end

    it "returns true when less" do
      expression = described_class.new([
        Flipper::Expressions::Value.new([1]),
        Flipper::Expressions::Value.new([2]),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns false when greater" do
      expression = described_class.new([
        Flipper::Expressions::Value.new([2]),
        Flipper::Expressions::Value.new([1]),
      ])

      expect(expression.evaluate).to be(false)
    end
  end
end
