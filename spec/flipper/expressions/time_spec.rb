RSpec.describe Flipper::Expressions::Time do
  let(:time) { Time.now.round }

  describe "#evaluate" do
    it "returns time for #to_s format" do
      expect(described_class.new(time.to_s).evaluate).to eq(time)
    end

    it "returns time for #iso8601 format" do
      expect(described_class.new(time.iso8601).evaluate).to eq(time)
    end
  end
end
