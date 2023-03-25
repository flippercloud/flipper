RSpec.describe Flipper::Expressions::Time do
  let(:time) { Time.now.round }

  describe "#initialize" do
    it "works with time" do
      expect(described_class.new(time).args).to eq([time.to_s])
    end

    it "works with Time#to_s" do
      expect(described_class.new(time.to_s).args).to eq([time.to_s])
    end

    it "works with array" do
      expect(described_class.new([time]).args).to eq([time.to_s])
    end
  end

  describe "#evaluate" do
    it "returns time for #to_s format" do
      expect(described_class.new(time.to_s).evaluate).to eq(time)
    end

    it "returns time for #iso8601 format" do
      expect(described_class.new(time.iso8601).evaluate).to eq(time)
    end
  end
end
