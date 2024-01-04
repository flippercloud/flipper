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
end
