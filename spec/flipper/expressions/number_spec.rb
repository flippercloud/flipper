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

    it "returns nil for values that can't be numbers" do
      [{}, [], { "a" => 1 }, [1]].each do |value|
        expect(described_class.call(value)).to be_nil
      end
    end
  end
end
