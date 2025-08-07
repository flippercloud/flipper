RSpec.describe Flipper::Expressions::Time do
  let(:time) { Time.now.round }

  describe "#call" do
    it "returns time for #to_s format" do
      expect(described_class.call(time.to_s)).to eq(time)
    end

    it "returns time for #iso8601 format" do
      expect(described_class.call(time.iso8601)).to eq(time)
    end
  end

  describe "#in_words" do
    it "returns parsed time" do
      arg = double("arg", value: "2025-01-01T00:00:00Z")
      expect(described_class.in_words(arg)).to eq("2025-01-01T00:00:00Z")
    end
  end
end
