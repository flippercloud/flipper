RSpec.describe Flipper::Expressions::Now do
  describe "#call" do
    it "returns current time" do
      expect(described_class.call.round).to eq(Time.now.round)
    end
  end
end
