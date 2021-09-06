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

  describe "#value" do
    it "returns Hash with type and value" do
      expect(described_class.new("plan").value).to eq({
        "type" => "property",
        "value" => "plan",
      })
    end
  end

  describe "#eq" do
    context "with string" do
      it "returns equal condition" do
        expect(described_class.new(:plan).eq("basic")).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "plan"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "string", "value" => "basic"}
        ))
      end
    end

    context "with boolean" do
      it "returns equal condition" do
        expect(described_class.new(:admin).eq(true)).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "admin"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "boolean", "value" => true}
        ))
      end
    end

    context "with integer" do
      it "returns equal condition" do
        expect(described_class.new(:age).eq(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "age"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "integer", "value" => 21}
        ))
      end
    end

    context "with array" do
      it "returns equal condition" do
        expect(described_class.new(:roles).eq(["admin"])).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "roles"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "array", "value" => ["admin"]}
        ))
      end
    end

    context "with nil" do
      it "returns equal condition" do
        expect(described_class.new(:admin).eq(nil)).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "admin"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "null", "value" => nil}
        ))
      end
    end
  end

  describe "#neq" do
    context "with string" do
      it "returns not equal condition" do
        expect(described_class.new(:plan).neq("basic")).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "plan"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "string", "value" => "basic"}
        ))
      end
    end

    context "with boolean" do
      it "returns not equal condition" do
        expect(described_class.new(:admin).neq(true)).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "admin"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "boolean", "value" => true}
        ))
      end
    end

    context "with integer" do
      it "returns not equal condition" do
        expect(described_class.new(:age).neq(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "age"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "integer", "value" => 21}
        ))
      end
    end

    context "with array" do
      it "returns not equal condition" do
        expect(described_class.new(:roles).neq(["admin"])).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "roles"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "array", "value" => ["admin"]}
        ))
      end
    end

    context "with nil" do
      it "returns not equal condition" do
        expect(described_class.new(:admin).neq(nil)).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "admin"},
          {"type" => "operator", "value" => "neq"},
          {"type" => "null", "value" => nil}
        ))
      end
    end
  end

  describe "#gt" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new(:age).gt(21)).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "age"},
          {"type" => "operator", "value" => "gt"},
          {"type" => "integer", "value" => 21}
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
          {"type" => "property", "value" => "age"},
          {"type" => "operator", "value" => "gte"},
          {"type" => "integer", "value" => 21}
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
          {"type" => "property", "value" => "age"},
          {"type" => "operator", "value" => "lt"},
          {"type" => "integer", "value" => 21}
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
          {"type" => "property", "value" => "age"},
          {"type" => "operator", "value" => "lte"},
          {"type" => "integer", "value" => 21}
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

  describe "#in" do
    context "with array" do
      it "returns condition" do
        expect(described_class.new(:role).in(["admin"])).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "role"},
          {"type" => "operator", "value" => "in"},
          {"type" => "array", "value" => ["admin"]}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new(:role).in("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new(:role).in(true) }.to raise_error(ArgumentError)
      end
    end

    context "with integer" do
      it "raises error" do
        expect { described_class.new(:role).in(21) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new(:role).in(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#nin" do
    context "with array" do
      it "returns condition" do
        expect(described_class.new(:role).nin(["admin"])).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "role"},
          {"type" => "operator", "value" => "nin"},
          {"type" => "array", "value" => ["admin"]}
        ))
      end
    end

    context "with string" do
      it "raises error" do
        expect { described_class.new(:role).nin("231") }.to raise_error(ArgumentError)
      end
    end

    context "with boolean" do
      it "raises error" do
        expect { described_class.new(:role).nin(true) }.to raise_error(ArgumentError)
      end
    end

    context "with integer" do
      it "raises error" do
        expect { described_class.new(:role).nin(21) }.to raise_error(ArgumentError)
      end
    end

    context "with nil" do
      it "raises error" do
        expect { described_class.new(:role).nin(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#percentage" do
    context "with integer" do
      it "returns condition" do
        expect(described_class.new(:flipper_id).percentage(25)).to eq(Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "flipper_id"},
          {"type" => "operator", "value" => "percentage"},
          {"type" => "integer", "value" => 25}
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
