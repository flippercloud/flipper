require 'helper'

RSpec.describe Flipper::Rules::Property do
  describe "#initialize" do
    it "works with string name" do
      property = described_class.new("plan")
      expect(property.name).to eq("plan")
    end

    it "works with symbol name" do
      property = described_class.new(:plan)
      expect(property.name).to eq("plan")
    end
  end

  describe "#to_h" do
    it "returns Hash with type and value" do
      expect(described_class.new("plan").to_h).to eq({
        "type" => "Property",
        "value" => "plan",
      })
    end
  end

  describe "equality" do
    it "returns true if equal" do
      expect(described_class.new("name").eql?(described_class.new("name"))).to be(true)
    end

    it "returns false if name does not match" do
      expect(described_class.new("name").eql?(described_class.new("age"))).to be(false)
    end

    it "returns false for different class" do
      expect(described_class.new("name").eql?(Object.new)).to be(false)
    end
  end

  describe "#eq" do
    context "with string" do
      it "returns equal condition" do
        expect(described_class.new(:plan).eq("basic")).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "plan"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "String", "value" => "basic"}
        ))
      end
    end

    context "with boolean" do
      it "returns equal condition" do
        expect(described_class.new(:admin).eq(true)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "admin"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Boolean", "value" => true}
        ))
      end
    end

    context "with integer" do
      it "returns equal condition" do
        expect(described_class.new(:age).eq(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "age"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with nil" do
      it "returns equal condition" do
        expect(described_class.new(:admin).eq(nil)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "admin"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Null", "value" => nil}
        ))
      end
    end
  end

  describe "#neq" do
    context "with string" do
      it "returns not equal condition" do
        expect(described_class.new(:plan).neq("basic")).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "plan"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "String", "value" => "basic"}
        ))
      end
    end

    context "with boolean" do
      it "returns not equal condition" do
        expect(described_class.new(:admin).neq(true)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "admin"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "Boolean", "value" => true}
        ))
      end
    end

    context "with integer" do
      it "returns not equal condition" do
        expect(described_class.new(:age).neq(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "age"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with nil" do
      it "returns not equal condition" do
        expect(described_class.new(:admin).neq(nil)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "admin"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "Null", "value" => nil}
        ))
      end
    end
  end

  describe "#gt" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new(:age).gt(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "age"},
          {"type" => "Operator", "value" => "gt"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new(:age).gt("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new(:age).gt(true) }.to raise_error(ArgumentError)
      end
    end

    context "with array" do
      it "raises error" do
        expect { described_class.new(:age).gt(["admin"]) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new(:age).gt(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#gte" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new(:age).gte(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "age"},
          {"type" => "Operator", "value" => "gte"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new(:age).gte("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new(:age).gte(true) }.to raise_error(ArgumentError)
      end
    end

    context "with array" do
      it "raises error" do
        expect { described_class.new(:age).gte(["admin"]) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new(:age).gte(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#lt" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new(:age).lt(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "age"},
          {"type" => "Operator", "value" => "lt"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new(:age).lt("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new(:age).lt(true) }.to raise_error(ArgumentError)
      end
    end

    context "with array" do
      it "raises error" do
        expect { described_class.new(:age).lt(["admin"]) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new(:age).lt(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#lte" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new(:age).lte(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "age"},
          {"type" => "Operator", "value" => "lte"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new(:age).lte("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new(:age).lte(true) }.to raise_error(ArgumentError)
      end
    end

    context "with array" do
      it "raises error" do
        expect { described_class.new(:age).lte(["admin"]) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new(:age).lte(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#percentage" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new(:flipper_id).percentage(25)).to eq(Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "flipper_id"},
          {"type" => "Operator", "value" => "percentage"},
          {"type" => "Integer", "value" => 25}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new(:flipper_id).percentage("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new(:flipper_id).percentage(true) }.to raise_error(ArgumentError)
      end
    end

    context "with array" do
      it "raises error" do
        expect { described_class.new(:flipper_id).percentage(["admin"]) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new(:flipper_id).percentage(nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
