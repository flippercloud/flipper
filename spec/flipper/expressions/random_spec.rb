RSpec.describe Flipper::Expressions::Random do
  describe "#call" do
    it "returns random number based on max" do
      100.times do
        expect(described_class.call(10)).to be_between(0, 10)
      end
    end
  end

  describe "#in_words" do
    it "formats as random function" do
      arg = double("arg", in_words: "100")
      expect(described_class.in_words(arg)).to eq("random(100)")
    end
  end
end
