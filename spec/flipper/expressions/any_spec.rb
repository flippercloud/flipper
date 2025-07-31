RSpec.describe Flipper::Expressions::Any do
  describe "#call" do
    it "returns true if any args evaluate as true" do
      expect(described_class.call(true, false)).to be(true)
    end

    it "returns false if all args evaluate as false" do
      expect(described_class.call(false, false)).to be(false)
    end

    it "returns false with empty args" do
      expect(described_class.call).to be(false)
    end
  end

  describe "#in_words" do
    it "returns single condition for one argument" do
      arg = double("arg", in_words: "user is admin")
      expect(described_class.in_words(arg)).to eq("user is admin")
    end

    it "returns 'any N conditions' for multiple arguments" do
      arg1 = double("arg1", in_words: "user is admin")
      arg2 = double("arg2", in_words: "age > 18")
      expect(described_class.in_words(arg1, arg2)).to eq("any 2 conditions")
    end
  end
end
