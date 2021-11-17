require 'helper'

RSpec.describe Flipper::Expressions::GreaterThanOrEqualTo do
  describe "#evaluate" do
    it "returns true when equal" do
      expression = described_class.new([
        Flipper::Expressions::Number.new([2]),
        Flipper::Expressions::Number.new([2]),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns true when greater" do
      expression = described_class.new([
        Flipper::Expressions::Number.new([2]),
        Flipper::Expressions::Number.new([1]),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns false when less" do
      expression = described_class.new([
        Flipper::Expressions::Number.new([1]),
        Flipper::Expressions::Number.new([2]),
      ])

      expect(expression.evaluate).to be(false)
    end
  end
end
