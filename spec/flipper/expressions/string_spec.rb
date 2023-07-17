RSpec.describe Flipper::Expressions::String do
  describe "#call" do
    it "returns String for Numeric" do
      expect(described_class.call(10)).to eq("10")
    end

    it "returns String" do
      expect(described_class.call("test")).to eq("test")
    end
  end
end
