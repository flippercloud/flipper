RSpec.describe Flipper::Expressions::String do
  describe "#call" do
    it "returns String for Numeric" do
      expect(described_class.call(10)).to eq("10")
    end

    it "returns String" do
      expect(described_class.call("test")).to eq("test")
    end
  end

  describe "#in_words" do
    it "delegates to argument's in_words method" do
      arg = double("arg", in_words: "constant value")
      expect(described_class.in_words(arg)).to eq("constant value")
    end
  end
end
