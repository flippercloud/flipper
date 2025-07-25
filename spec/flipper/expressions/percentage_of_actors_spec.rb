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

  describe "#in_words" do
    it "formats as 'X in Y% of actors'" do
      arg1 = double("arg1", in_words: "User;1")
      arg2 = double("arg2", in_words: "25")
      expect(described_class.in_words(arg1, arg2)).to eq("User;1 in 25% of actors")
    end
  end
end
