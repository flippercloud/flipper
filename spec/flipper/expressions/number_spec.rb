RSpec.describe Flipper::Expressions::Number do
  describe "#call" do
    it "returns Integer for Integer" do
      expect(described_class.call(10)).to be(10)
    end

    it "returns Float for Float" do
      expect(described_class.call(10.1)).to be(10.1)
      expect(described_class.call(10.0)).to be(10.0)
    end

    it "returns Integer for String" do
      expect(described_class.call('10')).to be(10)
    end

    it "returns Float for String" do
      expect(described_class.call('10.0')).to be(10.0)
      expect(described_class.call('10.1')).to be(10.1)
    end
  end

  describe "#in_words" do
    it "delegates to argument's in_words method" do
      arg = double("arg", in_words: "42")
      expect(described_class.in_words(arg)).to eq("42")
    end
  end
end
