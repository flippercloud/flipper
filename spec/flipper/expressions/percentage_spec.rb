RSpec.describe Flipper::Expressions::Percentage do
  describe "#call" do
    it "returns numeric" do
      expect(described_class.call(10)).to be(10.0)
    end

    it "returns 0 if less than 0" do
      expect(described_class.call(-1)).to be(0)
    end

    it "returns 100 if greater than 100" do
      expect(described_class.call(101)).to be(100)
    end
  end

  describe "#in_words" do
    it "formats as percentage" do
      arg = double("arg", value: 75)
      expect(described_class.in_words(arg)).to eq("75.0%")
    end
  end
end
