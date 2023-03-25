RSpec.describe Flipper::Expressions::Now do
  describe "#initialize" do
    it "ignores arguments" do
      expect(described_class.new("foo").args).to eq([])
    end
  end

  describe "#evaluate" do
    it "returns current time" do
      expect(described_class.new.evaluate.round).to eq(Time.now.round)
    end
  end
end
