require 'helper'

RSpec.describe Flipper::Expressions::Property do
  it "can initialize with string" do
    expect(described_class.new("flipper_id").args).to eq(["flipper_id"])
  end

  it "can initialize with symbol" do
    expect(described_class.new(:flipper_id).args).to eq(["flipper_id"])
  end

  it "can initialize with array of string" do
    expect(described_class.new(["flipper_id"]).args).to eq(["flipper_id"])
  end

  it "can initialize with array of symbol" do
    expect(described_class.new([:flipper_id]).args).to eq(["flipper_id"])
  end

  describe "#evaluate" do
    it "returns value for property key" do
      expression = described_class.new("flipper_id")
      properties = {
        "flipper_id" => "User;1",
      }
      expect(expression.evaluate(properties: properties)).to eq("User;1")
    end

    it "returns nil if key not found in properties" do
      expression = described_class.new("flipper_id")
      expect(expression.evaluate).to be(nil)
    end
  end
end
