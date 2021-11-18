require 'helper'

RSpec.describe Flipper::Expressions::Value do
  it "can initialize with string" do
    expect(described_class.new("basic").args).to eq(["basic"])
  end

  it "can initialize with number" do
    expect(described_class.new(1).args).to eq([1])
  end

  it "can initialize with array" do
    expect(described_class.new(["basic"]).args).to eq(["basic"])
    expect(described_class.new(["basic"]).args).to eq(["basic"])
  end

  describe "#evaluate" do
    it "returns arg" do
      expression = described_class.new(["basic"])
      expect(expression.evaluate).to eq("basic")
    end
  end
end
