require 'helper'

RSpec.describe Flipper::Expressions::NotEqual do
  describe "#evaluate" do
    it "returns true when not equal" do
      expression = described_class.new([
        Flipper::Expressions::String.new("basic"),
        Flipper::Expressions::String.new("plus"),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns false when equal" do
      expression = described_class.new([
        Flipper::Expressions::String.new("basic"),
        Flipper::Expressions::String.new("basic"),
      ])

      expect(expression.evaluate).to be(false)
    end
  end
end
