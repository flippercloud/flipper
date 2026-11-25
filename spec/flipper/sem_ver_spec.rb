RSpec.describe Flipper::SemVer do
  describe ".parse" do
    it "returns nil for strings with invalid bytes or encodings that aren't ASCII compatible" do
      expect(described_class.parse("2.1.0\xFF")).to be_nil
      expect(described_class.parse("2.1.0".encode("UTF-16LE"))).to be_nil
    end

    it "returns nil for values that aren't strings" do
      expect(described_class.parse(nil)).to be_nil
      expect(described_class.parse(123)).to be_nil
    end
  end
end
