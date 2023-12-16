RSpec.describe Flipper::Expressions::Equal do
  describe "#call" do
    it "returns true when equal" do
      expect(described_class.call("basic", "basic")).to be(true)
    end

    it "returns false when not equal" do
      expect(described_class.call("basic", "plus")).to be(false)
    end

    it "returns false when value evaluates to nil" do
      expect(described_class.call(nil, 1)).to be(false)
      expect(described_class.call(1, nil)).to be(false)
    end

    it "raises ArgumentError with no arguments" do
      expect { described_class.call }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError with one argument" do
      expect { described_class.call(10) }.to raise_error(ArgumentError)
    end
  end
end
