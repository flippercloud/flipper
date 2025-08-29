RSpec.describe Flipper::Expressions::All do
  describe "#call" do
    it "returns true if all args evaluate as true" do
      expect(described_class.call(true, true)).to be(true)
    end

    it "returns false if any args evaluate as false" do
      expect(described_class.call(false, true)).to be(false)
    end

    it "returns true with empty args" do
      expect(described_class.call).to be(true)
    end
  end

  describe "#in_words" do
    it "returns single condition for one argument" do
      arg = double("arg", in_words: "user is admin")
      expect(described_class.in_words(arg)).to eq("user is admin")
    end

    it "returns 'all N conditions' for multiple arguments" do
      arg1 = double("arg1", in_words: "user is admin")
      arg2 = double("arg2", in_words: "age > 18")
      expect(described_class.in_words(arg1, arg2)).to eq("all 2 conditions")
    end
  end
end
