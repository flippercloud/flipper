require 'helper'

RSpec.describe Flipper::Rules::Operator do
  describe ".wrap" do
    context "with Hash" do
      it "returns instance" do
        instance = described_class.wrap({"type" => "Operator", "value" => "eq"})
        expect(instance).to be_instance_of(described_class)
        expect(instance.name).to eq("eq")
      end
    end

    context "with instance" do
      it "returns intance" do
        instance = described_class.wrap(described_class.new("eq"))
        expect(instance).to be_instance_of(described_class)
        expect(instance.name).to eq("eq")
      end
    end
  end

  describe "#initialize" do
    it "works with string name" do
      instance = described_class.new("eq")
      expect(instance.name).to eq("eq")
    end

    it "works with symbol name" do
      instance = described_class.new(:eq)
      expect(instance.name).to eq("eq")
    end

    it "raises error for unknown operator" do
      expect { described_class.new("nope") }.to raise_error(ArgumentError, "Operator 'nope' could not be found")
    end
  end

  describe "#to_h" do
    it "returns Hash with type and value" do
      expect(described_class.new("eq").to_h).to eq({
        "type" => "Operator",
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
