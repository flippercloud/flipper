require 'helper'

RSpec.describe Flipper::Expressions::Number do
  it "can initialize with number" do
    expect(described_class.new(1).args).to eq([1])
  end

  it "can initialize with array" do
    expect(described_class.new([1]).args).to eq([1])
  end

  describe "#evaluate" do
    [1, 1.1, 1_000].each do |value|
      it "returns first arg for #{value}" do
        expression = described_class.new([value])
        expect(expression.evaluate).to eq(value)
      end
    end
  end
end
