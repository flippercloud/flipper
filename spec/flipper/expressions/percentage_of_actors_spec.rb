RSpec.describe Flipper::Expressions::PercentageOfActors do
  describe "#call" do
    it "returns true when string in percentage enabled" do
      expect(described_class.call("User;1", 42)).to be(true)
    end

    it "returns true when string in fractional percentage enabled" do
      expect(described_class.call("User;1", 41.687)).to be(true)
    end

    it "returns false when string in percentage enabled" do
      expect(described_class.call("User;1", 0)).to be(false)
    end

    it "changes value based on feature_name so not all actors get all features first" do
      expect(described_class.call("User;1", 70, context: {feature_name: "a"})).to be(true)
      expect(described_class.call("User;1", 70, context: {feature_name: "b"})).to be(false)
    end
  end
end
