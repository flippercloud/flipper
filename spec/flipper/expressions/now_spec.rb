RSpec.describe Flipper::Expressions::Now do
  describe "#call" do
    it "returns current time" do
      expect(described_class.call.round).to eq(Time.now.round)
    end

    it "defaults to UTC" do
      expect(described_class.call.zone).to eq("UTC")
    end
  end
end
