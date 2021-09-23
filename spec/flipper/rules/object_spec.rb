require 'helper'

RSpec.describe Flipper::Rules::Object do
  describe ".wrap" do
    context "with Hash" do
      it "returns instance" do
        instance = described_class.build({"type" => "Integer", "value" => 2})
        expect(instance).to be_instance_of(described_class)
        expect(instance.type).to eq("Integer")
        expect(instance.value).to eq(2)
      end
    end

    context "with instance" do
      it "returns instance" do
        instance = described_class.build(described_class.new(2))
        expect(instance).to be_instance_of(described_class)
        expect(instance.type).to eq("Integer")
        expect(instance.value).to eq(2)
      end
    end

    context "with string" do
      it "returns instance" do
        instance = described_class.build("test")
        expect(instance).to be_instance_of(described_class)
        expect(instance.type).to eq("String")
        expect(instance.value).to eq("test")
      end
    end

    context "with integer" do
      it "returns instance" do
        instance = described_class.build(21)
        expect(instance).to be_instance_of(described_class)
        expect(instance.type).to eq("Integer")
        expect(instance.value).to eq(21)
      end
    end

    context "with nil" do
      it "returns instance" do
        instance = described_class.build(nil)
        expect(instance).to be_instance_of(described_class)
        expect(instance.type).to eq("Null")
        expect(instance.value).to be(nil)
      end
    end

    context "with true" do
      it "returns instance" do
        instance = described_class.build(true)
        expect(instance).to be_instance_of(described_class)
        expect(instance.type).to eq("Boolean")
        expect(instance.value).to be(true)
      end
    end

    context "with false" do
      it "returns instance" do
        instance = described_class.build(false)
        expect(instance).to be_instance_of(described_class)
        expect(instance.type).to eq("Boolean")
        expect(instance.value).to be(false)
      end
    end

    context "with unsupported type" do
      it "raises ArgumentError" do
        expect {
          described_class.build(Set.new)
        }.to raise_error(ArgumentError, /is not a supported primitive\. Object must be one of: String, Integer, NilClass, TrueClass, FalseClass\./)
      end
    end
  end

  describe "#initialize" do
    context "with string" do
      it "returns instance" do
        instance = described_class.new("test")
        expect(instance.type).to eq("String")
        expect(instance.value).to eq("test")
      end
    end

    context "with integer" do
      it "returns instance" do
        instance = described_class.new(21)
        expect(instance.type).to eq("Integer")
        expect(instance.value).to eq(21)
      end
    end

    context "with nil" do
      it "returns instance" do
        instance = described_class.new(nil)
        expect(instance.type).to eq("Null")
        expect(instance.value).to be(nil)
      end
    end

    context "with true" do
      it "returns instance" do
        instance = described_class.new(true)
        expect(instance.type).to eq("Boolean")
        expect(instance.value).to be(true)
      end
    end

    context "with false" do
      it "returns instance" do
        instance = described_class.new(false)
        expect(instance.type).to eq("Boolean")
        expect(instance.value).to be(false)
      end
    end

    context "with unsupported type" do
      it "raises ArgumentError" do
        expect {
          described_class.new({})
        }.to raise_error(ArgumentError, /{} is not a supported primitive\. Object must be one of: String, Integer, NilClass, TrueClass, FalseClass\./)
      end
    end
  end

  describe "equality" do
    it "returns true if equal" do
      expect(described_class.new("test").eql?(described_class.new("test"))).to be(true)
    end

    it "returns false if value does not match" do
      expect(described_class.new("test").eql?(described_class.new("age"))).to be(false)
    end

    it "returns false for different class" do
      expect(described_class.new("test").eql?(Object.new)).to be(false)
    end
  end

  describe "#to_h" do
    it "returns Hash with type and value" do
      expect(described_class.new("test").to_h).to eq({
        "type" => "String",
        "value" => "test",
      })
    end
  end

  describe "#eq" do
    context "with string" do
      it "returns equal condition" do
        expect(described_class.new("plan").eq("basic")).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "plan"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "String", "value" => "basic"}
        ))
      end
    end

    context "with boolean" do
      it "returns equal condition" do
        expect(described_class.new("admin").eq(true)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "admin"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Boolean", "value" => true}
        ))
      end
    end

    context "with integer" do
      it "returns equal condition" do
        expect(described_class.new("age").eq(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "age"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with nil" do
      it "returns equal condition" do
        expect(described_class.new("admin").eq(nil)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "admin"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Null", "value" => nil}
        ))
      end
    end

    context "with property" do
      it "returns equal condition" do
        expect(described_class.new("admin").eq(Flipper.property(:name))).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "admin"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Property", "value" => "name"}
        ))
      end
    end

    context "with object" do
      it "returns equal condition" do
        expect(described_class.new("admin").eq(Flipper.object("test"))).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "admin"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "String", "value" => "test"}
        ))
      end
    end
  end

  describe "#neq" do
    context "with string" do
      it "returns not equal condition" do
        expect(described_class.new("plan").neq("basic")).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "plan"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "String", "value" => "basic"}
        ))
      end
    end

    context "with boolean" do
      it "returns not equal condition" do
        expect(described_class.new("admin").neq(true)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "admin"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "Boolean", "value" => true}
        ))
      end
    end

    context "with integer" do
      it "returns not equal condition" do
        expect(described_class.new("age").neq(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "age"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with nil" do
      it "returns not equal condition" do
        expect(described_class.new("admin").neq(nil)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "admin"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "Null", "value" => nil}
        ))
      end
    end

    context "with property" do
      it "returns not equal condition" do
        expect(described_class.new("plan").neq(Flipper.property(:name))).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "plan"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "Property", "value" => "name"}
        ))
      end
    end

    context "with object" do
      it "returns not equal condition" do
        expect(described_class.new("plan").neq(Flipper.object("test"))).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "plan"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "String", "value" => "test"}
        ))
      end
    end
  end

  describe "#gt" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new("age").gt(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "age"},
          {"type" => "Operator", "value" => "gt"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new(21).gt(Flipper.property(:age))).to eq(Flipper::Rules::Condition.new(
          {"type" => "Integer", "value" => 21},
          {"type" => "Operator", "value" => "gt"},
          {"type" => "Property", "value" => "age"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new(21).gt(Flipper.object(22))).to eq(Flipper::Rules::Condition.new(
          {"type" => "Integer", "value" => 21},
          {"type" => "Operator", "value" => "gt"},
          {"type" => "Integer", "value" => 22}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new("age").gt("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new("age").gt(true) }.to raise_error(ArgumentError)
      end
    end

    context "with array" do
      it "raises error" do
        expect { described_class.new("age").gt(["admin"]) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new("age").gt(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#gte" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new("age").gte(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "age"},
          {"type" => "Operator", "value" => "gte"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new(21).gte(Flipper.property(:age))).to eq(Flipper::Rules::Condition.new(
          {"type" => "Integer", "value" => 21},
          {"type" => "Operator", "value" => "gte"},
          {"type" => "Property", "value" => "age"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new(21).gte(Flipper.object(22))).to eq(Flipper::Rules::Condition.new(
          {"type" => "Integer", "value" => 21},
          {"type" => "Operator", "value" => "gte"},
          {"type" => "Integer", "value" => 22}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new("age").gte("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new("age").gte(true) }.to raise_error(ArgumentError)
      end
    end

    context "with array" do
      it "raises error" do
        expect { described_class.new("age").gte(["admin"]) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new("age").gte(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#lt" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new("age").lt(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "age"},
          {"type" => "Operator", "value" => "lt"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new(21).lt(Flipper.property(:age))).to eq(Flipper::Rules::Condition.new(
          {"type" => "Integer", "value" => 21},
          {"type" => "Operator", "value" => "lt"},
          {"type" => "Property", "value" => "age"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new(21).lt(Flipper.object(22))).to eq(Flipper::Rules::Condition.new(
          {"type" => "Integer", "value" => 21},
          {"type" => "Operator", "value" => "lt"},
          {"type" => "Integer", "value" => 22}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new("age").lt("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new("age").lt(true) }.to raise_error(ArgumentError)
      end
    end

    context "with array" do
      it "raises error" do
        expect { described_class.new("age").lt(["admin"]) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new("age").lt(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#lte" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new("age").lte(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "age"},
          {"type" => "Operator", "value" => "lte"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new(21).lte(Flipper.property(:age))).to eq(Flipper::Rules::Condition.new(
          {"type" => "Integer", "value" => 21},
          {"type" => "Operator", "value" => "lte"},
          {"type" => "Property", "value" => "age"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new(21).lte(Flipper.object(22))).to eq(Flipper::Rules::Condition.new(
          {"type" => "Integer", "value" => 21},
          {"type" => "Operator", "value" => "lte"},
          {"type" => "Integer", "value" => 22}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new("age").lte("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new("age").lte(true) }.to raise_error(ArgumentError)
      end
    end

    context "with array" do
      it "raises error" do
        expect { described_class.new("age").lte(["admin"]) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new("age").lte(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#percentage" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new("flipper_id").percentage(25)).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "flipper_id"},
          {"type" => "Operator", "value" => "percentage"},
          {"type" => "Integer", "value" => 25}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new("flipper_id").percentage(Flipper.property(:percentage))).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "flipper_id"},
          {"type" => "Operator", "value" => "percentage"},
          {"type" => "Property", "value" => "percentage"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new("flipper_id").percentage(Flipper.object(21))).to eq(Flipper::Rules::Condition.new(
          {"type" => "String", "value" => "flipper_id"},
          {"type" => "Operator", "value" => "percentage"},
          {"type" => "Integer", "value" => 21}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new("flipper_id").percentage("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new("flipper_id").percentage(true) }.to raise_error(ArgumentError)
      end
    end

    context "with array" do
      it "raises error" do
        expect { described_class.new("flipper_id").percentage(["admin"]) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new("flipper_id").percentage(nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
