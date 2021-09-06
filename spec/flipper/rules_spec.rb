require 'helper'

RSpec.describe Flipper::Rules do
  describe ".type_of" do
    context "for string" do
      it "returns string" do
        expect(described_class.type_of("test")).to eq("string")
      end
    end

    context "for integer" do
      it "returns integer" do
        expect(described_class.type_of(21)).to eq("integer")
      end
    end

    context "for nil" do
      it "returns nil" do
        expect(described_class.type_of(nil)).to eq("null")
      end
    end

    context "for true" do
      it "returns boolean" do
        expect(described_class.type_of(true)).to eq("boolean")
      end
    end

    context "for false" do
      it "returns boolean" do
        expect(described_class.type_of(false)).to eq("boolean")
      end
    end

    context "for array" do
      it "returns array" do
        expect(described_class.type_of([1, 2, 3])).to eq("array")
      end
    end

    context "for unsupported type" do
      it "returns nil" do
        expect(described_class.type_of(Object.new)).to be(nil)
      end
    end
  end

  describe ".typed" do
    context "with string" do
      it "returns array of type and value" do
        expect(described_class.typed("test")).to eq(["string", "test"])
      end
    end

    context "with integer" do
      it "returns array of type and value" do
        expect(described_class.typed(21)).to eq(["integer", 21])
      end
    end

    context "with nil" do
      it "returns array of type and value" do
        expect(described_class.typed(nil)).to eq(["null", nil])
      end
    end

    context "with true" do
      it "returns array of type and value" do
        expect(described_class.typed(true)).to eq(["boolean", true])
      end
    end

    context "with false" do
      it "returns array of type and value" do
        expect(described_class.typed(false)).to eq(["boolean", false])
      end
    end

    context "with array" do
      it "returns array of type and value" do
        expect(described_class.typed(["test"])).to eq(["array", ["test"]])
      end
    end

    context "with unsupported type" do
      it "returns array of type and value" do
        expect { described_class.typed({}) }.to raise_error(ArgumentError, /{} is an unsupported type\. Object must be one of: String, Integer, NilClass, TrueClass, FalseClass, Array\./)
      end
    end
  end
end
