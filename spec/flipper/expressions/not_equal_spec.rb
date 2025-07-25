RSpec.describe Flipper::Expressions::NotEqual do
  describe "#call" do
    it "returns true when not equal" do
      expect(described_class.call("basic", "plus")).to be(true)
    end

    it "returns false when equal" do
      expect(described_class.call("basic", "basic")).to be(false)
    end

    it "raises ArgumentError for more arguments" do
      expect { described_class.call(20, 10, 20).evaluate }.to raise_error(ArgumentError)
    end
  end

  describe "#in_words" do
    it "formats comparison in words" do
      left = double("left", in_words: "role")
      right = double("right", in_words: "guest")
      expect(described_class.in_words(left, right)).to eq("role is not equal to guest")
    end
  end
end
