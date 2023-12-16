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
end
