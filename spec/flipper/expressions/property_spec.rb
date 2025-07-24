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

  describe "#in_words" do
    it "delegates to argument's in_words method" do
      arg = double("arg", in_words: "user_id")
      expect(described_class.in_words(arg)).to eq("user_id")
    end
  end
end
