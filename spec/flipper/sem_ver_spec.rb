RSpec.describe Flipper::SemVer do
  describe ".parse" do
    it "parses a version" do
      expect(described_class.parse("2.3.1").to_s).to eq("2.3.1")
    end

    it "returns nil for strings with invalid bytes" do
      expect(described_class.parse("2.1.0\xFF")).to be_nil
    end

    it "returns nil for strings in encodings that aren't ASCII compatible" do
      expect(described_class.parse("2.1.0".encode("UTF-16LE"))).to be_nil
    end

    it "returns nil for values that aren't strings" do
      [nil, 123, 2.3, :"2.3.1"].each do |value|
        expect(described_class.parse(value)).to be_nil, "expected #{value.inspect} to be nil"
      end
    end
  end
end
