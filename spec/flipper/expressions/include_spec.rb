RSpec.describe Flipper::Expressions::Include do
  describe "#call" do
    it "returns true when left includes right" do
      expect(described_class.call([2], 2)).to be(true)
    end

    it "returns false when left does not include right" do
      expect(described_class.call([2], "2")).to be(false)
    end

    it "returns false when left does not respond to #include?" do
      expect(described_class.call(nil, nil)).to be(false)
    end

    it "raises ArgumentError with no arguments" do
      expect { described_class.call }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError with one argument" do
      expect { described_class.call(10) }.to raise_error(ArgumentError)
    end
  end
end
