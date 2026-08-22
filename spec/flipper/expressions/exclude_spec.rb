RSpec.describe Flipper::Expressions::Exclude do
  describe "#call" do
    it "returns true when array does not include value" do
      expect(described_class.call(["basic", "plus"], "premium")).to be(true)
    end

    it "returns false when array includes value" do
      expect(described_class.call(["basic", "plus"], "basic")).to be(false)
    end

    it "returns true when array includes value of different type" do
      expect(described_class.call([2], "2")).to be(true)
    end

    it "returns false when string includes substring" do
      expect(described_class.call("engineering-team", "team")).to be(false)
    end

    it "returns true when string does not include substring" do
      expect(described_class.call("engineering-team", "sales")).to be(true)
    end

    it "returns true when left is nil" do
      expect(described_class.call(nil, "basic")).to be(true)
    end

    it "returns true when left is not an array or string" do
      expect(described_class.call({"basic" => true}, "basic")).to be(true)
      expect(described_class.call(10, 1)).to be(true)
    end

    it "raises ArgumentError with no arguments" do
      expect { described_class.call }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError with one argument" do
      expect { described_class.call(["basic"]) }.to raise_error(ArgumentError)
    end
  end
end
