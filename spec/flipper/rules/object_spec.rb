require 'helper'

RSpec.describe Flipper::Rules::Object do
  describe "#initialize" do
    context "with string" do
      it "returns array of type and value" do
        instance = described_class.new("test")
        expect(instance.type).to eq("string")
        expect(instance.value).to eq("test")
      end
    end

    context "with integer" do
      it "returns array of type and value" do
        instance = described_class.new(21)
        expect(instance.type).to eq("integer")
        expect(instance.value).to eq(21)
      end
    end

    context "with nil" do
      it "returns array of type and value" do
        instance = described_class.new(nil)
        expect(instance.type).to eq("null")
        expect(instance.value).to be(nil)
      end
    end

    context "with true" do
      it "returns array of type and value" do
        instance = described_class.new(true)
        expect(instance.type).to eq("boolean")
        expect(instance.value).to be(true)
      end
    end

    context "with false" do
      it "returns array of type and value" do
        instance = described_class.new(false)
        expect(instance.type).to eq("boolean")
        expect(instance.value).to be(false)
      end
    end

    context "with array" do
      it "returns array of type and value" do
        instance = described_class.new(["test"])
        expect(instance.type).to eq("array")
        expect(instance.value).to eq(["test"])
      end
    end

    context "with unsupported type" do
      it "returns array of type and value" do
        expect {
          described_class.new({})
        }.to raise_error(ArgumentError, /{} is not a supported primitive\. Object must be one of: String, Integer, NilClass, TrueClass, FalseClass, Array\./)
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
        "type" => "string",
        "value" => "test",
      })
    end
  end

  describe "#eq" do
    context "with string" do
      it "returns equal condition" do
        expect(described_class.new("plan").eq("basic")).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "plan"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "string", "value" => "basic"}
        ))
      end
    end

    context "with boolean" do
      it "returns equal condition" do
        expect(described_class.new("admin").eq(true)).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "admin"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "boolean", "value" => true}
        ))
      end
    end

    context "with integer" do
      it "returns equal condition" do
        expect(described_class.new("age").eq(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "age"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "integer", "value" => 21}
        ))
      end
    end

    context "with array" do
      it "returns equal condition" do
        expect(described_class.new("roles").eq(["admin"])).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "roles"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "array", "value" => ["admin"]}
        ))
      end
    end

    context "with nil" do
      it "returns equal condition" do
        expect(described_class.new("admin").eq(nil)).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "admin"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "null", "value" => nil}
        ))
      end
    end

    context "with property" do
      it "returns equal condition" do
        expect(described_class.new("admin").eq(Flipper.property(:name))).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "admin"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "property", "value" => "name"}
        ))
      end
    end

    context "with object" do
      it "returns equal condition" do
        expect(described_class.new("admin").eq(Flipper.object("test"))).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "admin"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "string", "value" => "test"}
        ))
      end
    end
  end

  describe "#neq" do
    context "with string" do
      it "returns not equal condition" do
        expect(described_class.new("plan").neq("basic")).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "plan"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "string", "value" => "basic"}
        ))
      end
    end

    context "with boolean" do
      it "returns not equal condition" do
        expect(described_class.new("admin").neq(true)).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "admin"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "boolean", "value" => true}
        ))
      end
    end

    context "with integer" do
      it "returns not equal condition" do
        expect(described_class.new("age").neq(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "age"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "integer", "value" => 21}
        ))
      end
    end

    context "with array" do
      it "returns not equal condition" do
        expect(described_class.new("roles").neq(["admin"])).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "roles"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "array", "value" => ["admin"]}
        ))
      end
    end

    context "with nil" do
      it "returns not equal condition" do
        expect(described_class.new("admin").neq(nil)).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "admin"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "null", "value" => nil}
        ))
      end
    end

    context "with property" do
      it "returns not equal condition" do
        expect(described_class.new("plan").neq(Flipper.property(:name))).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "plan"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "property", "value" => "name"}
        ))
      end
    end

    context "with object" do
      it "returns not equal condition" do
        expect(described_class.new("plan").neq(Flipper.object("test"))).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "plan"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "string", "value" => "test"}
        ))
      end
    end
  end

  describe "#gt" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new("age").gt(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "age"},
          {"type" => "operator", "value" => "gt"},
          {"type" => "integer", "value" => 21}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new(21).gt(Flipper.property(:age))).to eq(Flipper::Rules::Condition.new(
          {"type" => "integer", "value" => 21},
          {"type" => "operator", "value" => "gt"},
          {"type" => "property", "value" => "age"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new(21).gt(Flipper.object(22))).to eq(Flipper::Rules::Condition.new(
          {"type" => "integer", "value" => 21},
          {"type" => "operator", "value" => "gt"},
          {"type" => "integer", "value" => 22}
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
          {"type" => "string", "value" => "age"},
          {"type" => "operator", "value" => "gte"},
          {"type" => "integer", "value" => 21}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new(21).gte(Flipper.property(:age))).to eq(Flipper::Rules::Condition.new(
          {"type" => "integer", "value" => 21},
          {"type" => "operator", "value" => "gte"},
          {"type" => "property", "value" => "age"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new(21).gte(Flipper.object(22))).to eq(Flipper::Rules::Condition.new(
          {"type" => "integer", "value" => 21},
          {"type" => "operator", "value" => "gte"},
          {"type" => "integer", "value" => 22}
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
          {"type" => "string", "value" => "age"},
          {"type" => "operator", "value" => "lt"},
          {"type" => "integer", "value" => 21}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new(21).lt(Flipper.property(:age))).to eq(Flipper::Rules::Condition.new(
          {"type" => "integer", "value" => 21},
          {"type" => "operator", "value" => "lt"},
          {"type" => "property", "value" => "age"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new(21).lt(Flipper.object(22))).to eq(Flipper::Rules::Condition.new(
          {"type" => "integer", "value" => 21},
          {"type" => "operator", "value" => "lt"},
          {"type" => "integer", "value" => 22}
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
          {"type" => "string", "value" => "age"},
          {"type" => "operator", "value" => "lte"},
          {"type" => "integer", "value" => 21}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new(21).lte(Flipper.property(:age))).to eq(Flipper::Rules::Condition.new(
          {"type" => "integer", "value" => 21},
          {"type" => "operator", "value" => "lte"},
          {"type" => "property", "value" => "age"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new(21).lte(Flipper.object(22))).to eq(Flipper::Rules::Condition.new(
          {"type" => "integer", "value" => 21},
          {"type" => "operator", "value" => "lte"},
          {"type" => "integer", "value" => 22}
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

  describe "#in" do
    context "with array" do
      it "returns condition" do
        expect(described_class.new("role").in(["admin"])).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "role"},
          {"type" => "operator", "value" => "in"},
          {"type" => "array", "value" => ["admin"]}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new("admin").in(Flipper.property(:roles))).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "admin"},
          {"type" => "operator", "value" => "in"},
          {"type" => "property", "value" => "roles"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new("admin").in(Flipper.object(["admin"]))).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "admin"},
          {"type" => "operator", "value" => "in"},
          {"type" => "array", "value" => ["admin"]}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new("role").in("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new("role").in(true) }.to raise_error(ArgumentError)
      end
    end

    context "with integer" do
      it "raises error" do
        expect { described_class.new("role").in(21) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new("role").in(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#nin" do
    context "with array" do
      it "returns condition" do
        expect(described_class.new("role").nin(["admin"])).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "role"},
          {"type" => "operator", "value" => "nin"},
          {"type" => "array", "value" => ["admin"]}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new("admin").nin(Flipper.property(:roles))).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "admin"},
          {"type" => "operator", "value" => "nin"},
          {"type" => "property", "value" => "roles"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new("admin").nin(Flipper.object(["admin"]))).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "admin"},
          {"type" => "operator", "value" => "nin"},
          {"type" => "array", "value" => ["admin"]}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new("role").nin("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new("role").nin(true) }.to raise_error(ArgumentError)
      end
    end

    context "with integer" do
      it "raises error" do
        expect { described_class.new("role").nin(21) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new("role").nin(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#percentage" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new("flipper_id").percentage(25)).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "flipper_id"},
          {"type" => "operator", "value" => "percentage"},
          {"type" => "integer", "value" => 25}
        ))
      end
    end

    context "with property" do
      it "returns condition" do
        expect(described_class.new("flipper_id").percentage(Flipper.property(:percentage))).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "flipper_id"},
          {"type" => "operator", "value" => "percentage"},
          {"type" => "property", "value" => "percentage"}
        ))
      end
    end

    context "with object" do
      it "returns condition" do
        expect(described_class.new("flipper_id").percentage(Flipper.object(21))).to eq(Flipper::Rules::Condition.new(
          {"type" => "string", "value" => "flipper_id"},
          {"type" => "operator", "value" => "percentage"},
          {"type" => "integer", "value" => 21}
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
