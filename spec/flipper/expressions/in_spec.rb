RSpec.describe Flipper::Expressions::In do
  describe "#call" do
    it "returns true when array includes value" do
      expect(described_class.call("basic", ["basic", "plus"])).to be(true)
    end

    it "returns false when array does not include value" do
      expect(described_class.call("premium", ["basic", "plus"])).to be(false)
    end

    it "returns false when array includes value of different type" do
      expect(described_class.call("2", [2])).to be(false)
    end

    it "returns false when value is nil" do
      expect(described_class.call(nil, ["basic"])).to be(false)
    end

    it "returns false when right is not an array" do
      expect(described_class.call("basic", "basic")).to be(false)
      expect(described_class.call("basic", nil)).to be(false)
    end

    it "raises ArgumentError with no arguments" do
      expect { described_class.call }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError with one argument" do
      expect { described_class.call("basic") }.to raise_error(ArgumentError)
    end
  end
end
