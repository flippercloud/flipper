RSpec.describe Flipper::Expressions::Property do
  describe "#call" do
    it "returns value for property key" do
      context = { properties: { "flipper_id" => "User;1" } }
      expect(described_class.call("flipper_id", context: context)).to eq("User;1")
    end

    it "returns nil if key not found in properties" do
      context = { properties: { } }
      expect(described_class.call("flipper_id", context: context)).to be(nil)
    end
  end
end
