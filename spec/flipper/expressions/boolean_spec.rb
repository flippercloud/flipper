RSpec.describe Flipper::Expressions::Boolean do
  describe "#call" do
    [true, 'true', 1, '1'].each do |value|
      it "returns a true for #{value.inspect}" do
        expect(described_class.call(value)).to be(true)
      end
    end

    [false, 'false', 0, '0', nil].each do |value|
      it "returns a true for #{value.inspect}" do
        expect(described_class.call(value)).to be(false)
      end
    end
  end

  describe "#in_words" do
    it "returns boolean value" do
      arg = double("arg", value: true)
      expect(described_class.in_words(arg)).to eq(true)
    end

    it "converts values to boolean" do
      arg = double("arg", value: "false")
      expect(described_class.in_words(arg)).to eq(false)
    end
  end
end
