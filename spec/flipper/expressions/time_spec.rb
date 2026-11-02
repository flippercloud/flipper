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

    it "returns utc time for Time input" do
      result = described_class.call(time.getlocal("+09:00"))
      expect(result).to eq(time)
      expect(result.utc?).to be(true)
    end

    it "leaves the Time it was given in its own zone" do
      value = time.getlocal("+09:00")
      described_class.call(value)
      expect(value.utc_offset).to eq(9 * 3600)
    end

    it "returns time for DateTime input" do
      expect(described_class.call(time.to_datetime)).to eq(time)
    end

    it "returns time for Date input" do
      expect(described_class.call(Date.new(2026, 11, 1))).to eq(Date.new(2026, 11, 1).to_time)
    end

    it "returns nil for values that aren't times" do
      [nil, true, {}, [], "", "not a time", "2026-13-45", Float::INFINITY, Float::NAN].each do |value|
        expect(described_class.call(value)).to be_nil
      end
    end
  end
end
