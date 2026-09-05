require "flipper/ui/util"

RSpec.describe Flipper::UI::Util do
  describe "#blank?" do
    context "with a string" do
      it "returns true if blank" do
        expect(described_class.blank?(nil)).to be(true)
        expect(described_class.blank?("")).to be(true)
        expect(described_class.blank?("   ")).to be(true)
      end

      it "returns false if not blank" do
        expect(described_class.blank?("nope")).to be(false)
      end
    end
  end

  describe "#normalize_feature_name" do
    it "keeps accented and non-latin characters" do
      expect(described_class.normalize_feature_name("caf\u00E9")).to eq("caf\u00E9")
      expect(described_class.normalize_feature_name("\u65B0\u6A5F\u80FD")).to eq("\u65B0\u6A5F\u80FD")
    end

    it "removes invisible characters like zero width spaces, joiners, bom and soft hyphens" do
      expect(described_class.normalize_feature_name("f\u200Bea\u2060ture")).to eq("feature")
      expect(described_class.normalize_feature_name("\uFEFFfeat\u00ADure")).to eq("feature")
    end

    it "trims unicode whitespace like non-breaking and ideographic spaces" do
      expect(described_class.normalize_feature_name("\u00A0feature\u3000")).to eq("feature")
    end

    it "strips surrounding whitespace" do
      expect(described_class.normalize_feature_name("  notifications_next  ")).to eq("notifications_next")
    end

    it "returns empty string for nil" do
      expect(described_class.normalize_feature_name(nil)).to eq("")
    end
  end
end
