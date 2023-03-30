RSpec.describe Flipper::Expressions::Now do
  describe "#call" do
    it "returns current time" do
      expect(described_class.call).to be_within(2).of(Time.now.utc)
    end

    it "defaults to UTC" do
      expect(described_class.call.zone).to eq("UTC")
    end
  end
end
