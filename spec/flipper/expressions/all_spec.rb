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
end
