RSpec.describe Flipper::Expressions::Now do
  describe "#evaluate" do
    it "returns current time" do
      expect(described_class.new.evaluate.round).to eq(Time.now.round)
    end
  end
end
