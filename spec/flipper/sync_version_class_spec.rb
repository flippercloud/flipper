RSpec.describe Flipper::SyncVersion do
  describe ".from_header" do
    it "builds a version from an integer string" do
      expect(described_class.from_header("abc", "42")).to eq(described_class.new("abc", 42))
    end

    it "returns nil for missing or malformed values" do
      [nil, "", "nope", "4.2", "0x10"].each do |value|
        expect(described_class.from_header("abc", value)).to be_nil
      end
    end
  end

  describe ".parse" do
    it "round trips #to_s" do
      version = described_class.new("abc", 42)
      expect(described_class.parse(version.to_s)).to eq(version)
    end

    it "returns nil for missing or malformed values" do
      [nil, "", "42", ":42", "abc:", "abc:nope"].each do |value|
        expect(described_class.parse(value)).to be_nil
      end
    end
  end

  describe "#older_than?" do
    let(:version) { described_class.new("abc", 10) }

    it "compares numbers within a scope" do
      expect(version.older_than?(described_class.new("abc", 11))).to be(true)
      expect(version.older_than?(described_class.new("abc", 10))).to be(false)
      expect(version.older_than?(described_class.new("abc", 9))).to be(false)
    end

    it "is never older than a version from another scope" do
      expect(version.older_than?(described_class.new("xyz", 100))).to be(false)
    end

    it "is not older than nil" do
      expect(version.older_than?(nil)).to be(false)
    end
  end
end
