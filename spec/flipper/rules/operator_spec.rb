require 'helper'

RSpec.describe Flipper::Rules::Operator do
  describe ".build" do
    context "with Hash" do
      it "returns instance" do
        instance = described_class.build({"type" => "Operator", "value" => "eq"})
        expect(instance).to be_a(Flipper::Rules::Operators::Base)
        expect(instance.name).to eq("eq")
      end
    end

    context "with String" do
      it "returns instance" do
        instance = described_class.build("eq")
        expect(instance).to be_a(Flipper::Rules::Operators::Base)
        expect(instance.name).to eq("eq")
      end
    end

    context "with Symbol" do
      it "returns instance" do
        instance = described_class.build(:eq)
        expect(instance).to be_a(Flipper::Rules::Operators::Base)
        expect(instance.name).to eq("eq")
      end
    end

    context "with instance" do
      it "returns intance" do
        instance = described_class.build(described_class.build(:eq))
        expect(instance).to be_instance_of(Flipper::Rules::Operators::Eq)
        expect(instance.name).to eq("eq")
      end
    end
  end

  describe "#initialize" do
    it "works with string name" do
      instance = described_class.build("eq")
      expect(instance.name).to eq("eq")
    end

    it "works with symbol name" do
      instance = described_class.build(:eq)
      expect(instance.name).to eq("eq")
    end
  end

  describe "#to_h" do
    it "returns Hash with type and value" do
      expect(described_class.build("eq").to_h).to eq({
        "type" => "Operator",
        "value" => "eq",
      })
    end
  end

  describe "equality" do
    it "returns true if equal" do
      expect(described_class.build("eq").eql?(described_class.build("eq"))).to be(true)
    end

    it "returns false if name does not match" do
      expect(described_class.build("eq").eql?(described_class.build("neq"))).to be(false)
    end

    it "returns false for different class" do
      expect(described_class.build("eq").eql?(Object.new)).to be(false)
    end
  end
end
