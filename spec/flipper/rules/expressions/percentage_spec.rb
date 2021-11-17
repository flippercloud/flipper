require 'helper'

RSpec.describe Flipper::Expressions::Percentage do
  describe "#evaluate" do
    it "returns true when string in percentage enabled" do
      expression = described_class.new([
        Flipper::Expressions::String.new("User;1"),
        Flipper::Expressions::Number.new(100),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns false when string in percentage enabled" do
      expression = described_class.new([
        Flipper::Expressions::String.new("User;1"),
        Flipper::Expressions::Number.new(0),
      ])

      expect(expression.evaluate).to be(false)
    end

    it "changes value based on feature_name so not all actors get all features first" do
      expression = described_class.new([
        Flipper::Expressions::String.new("User;1"),
        Flipper::Expressions::Number.new(70),
      ])

      expect(expression.evaluate(feature_name: "a")).to be(true)
      expect(expression.evaluate(feature_name: "b")).to be(false)
    end
  end
end
