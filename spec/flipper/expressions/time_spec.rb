RSpec.describe Flipper::Expressions::Time do
  let(:time) { Time.now.round }

  describe "#call" do
    it "returns time for #to_s format" do
      expect(described_class.call(time.to_s)).to eq(time)
    end

    it "returns time for #iso8601 format" do
      expect(described_class.call(time.iso8601)).to eq(time)
    end

    it "returns time for epoch integer" do
      expect(described_class.call(time.to_i)).to eq(Time.at(time.to_i).utc)
    end

    it "returns time for epoch float" do
      expect(described_class.call(time.to_f)).to be_within(0.001).of(time)
    end

    it "returns utc for string input" do
      expect(described_class.call(time.to_s).utc?).to be(true)
    end

    it "returns utc for numeric input" do
      expect(described_class.call(time.to_i).utc?).to be(true)
    end
  end
end
