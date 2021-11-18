require 'helper'

RSpec.describe Flipper::Expressions::Random do
  it "can initialize with number" do
    expect(described_class.new(1).args).to eq([1])
  end

  it "can initialize with array" do
    expect(described_class.new([1]).args).to eq([1])
  end

  describe "#evaluate" do
    it "returns random number based on seed" do
      expression = described_class.new([10])
      result = expression.evaluate
      expect(result).to be >= 0
      expect(result).to be <= 10
    end
  end
end
