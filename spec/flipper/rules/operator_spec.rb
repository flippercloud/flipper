require 'helper'

RSpec.describe Flipper::Rules::Operator do
  describe "#initialize" do
    it "works with string name" do
      property = described_class.new("eq")
      expect(property.name).to eq("eq")
    end

    it "works with symbol name" do
      property = described_class.new(:eq)
      expect(property.name).to eq("eq")
    end
  end

  describe "#to_h" do
    it "returns Hash with type and value" do
      expect(described_class.new("eq").to_h).to eq({
        "type" => "operator",
        "value" => "eq",
      })
    end
  end

  describe "equality" do
    it "returns true if equal" do
      expect(described_class.new("eq").eql?(described_class.new("eq"))).to be(true)
    end

    it "returns false if name does not match" do
      expect(described_class.new("eq").eql?(described_class.new("neq"))).to be(false)
    end

    it "returns false for different class" do
      expect(described_class.new("eq").eql?(Object.new)).to be(false)
    end
  end
end
