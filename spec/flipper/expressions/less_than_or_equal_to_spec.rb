RSpec.describe Flipper::Expressions::LessThanOrEqualTo do
  describe "#call" do
    it "returns true when equal" do
      expect(described_class.call(2, 2)).to be(true)
    end

    it "returns true when less" do
      expect(described_class.call(1, 2)).to be(true)
    end

    it "returns false when greater" do
      expect(described_class.call(2, 1)).to be(false)
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

  describe "#in_words" do
    it "formats comparison in words" do
      left = double("left", in_words: "temperature")
      right = double("right", in_words: "32")
      expect(described_class.in_words(left, right)).to eq("temperature is less than or equal to 32")
    end
  end
end
