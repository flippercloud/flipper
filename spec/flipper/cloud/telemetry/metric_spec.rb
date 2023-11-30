require 'flipper/cloud/telemetry/metric'

RSpec.describe Flipper::Cloud::Telemetry::Metric do
  it 'has key, result and time' do
    metric = described_class.new(:search, true, 1696793160)
    expect(metric.key).to eq(:search)
    expect(metric.result).to eq(true)
    expect(metric.time).to eq(1696793160)
  end

  it "clamps time to minute" do
    metric = described_class.new(:search, true, 1696793204)
    expect(metric.time).to eq(1696793160)
  end

  describe "#eql?" do
    it "returns true when key, time and result are the same" do
      metric = described_class.new(:search, true, 1696793204)
      other = described_class.new(:search, true, 1696793204)
      expect(metric.eql?(other)).to be(true)
    end

    it "returns false for other class" do
      metric = described_class.new(:search, true, 1696793204)
      other = Object.new
      expect(metric.eql?(other)).to be(false)
    end

    it "returns false for sub class" do
      metric = described_class.new(:search, true, 1696793204)
      other = Class.new(described_class).new(:search, true, 1696793204)
      expect(metric.eql?(other)).to be(false)
    end

    it "returns false if key is different" do
      metric = described_class.new(:search, true, 1696793204)
      other = described_class.new(:other, true, 1696793204)
      expect(metric.eql?(other)).to be(false)
    end

    it "returns false if time is different" do
      metric = described_class.new(:search, true, 1696793204)
      other = described_class.new(:search, true, 1696793204 - 60 - 60)
      expect(metric.eql?(other)).to be(false)
    end

    it "returns true with different times if times are in same minute" do
      metric = described_class.new(:search, true, 1696793204)
      other = described_class.new(:search, true, 1696793206)
      expect(metric.eql?(other)).to be(true)
    end

    it "returns false if result is different" do
      metric = described_class.new(:search, true, 1696793204)
      other = described_class.new(:search, false, 1696793204)
      expect(metric.eql?(other)).to be(false)
    end
  end

  describe "#hash" do
    it "returns hash based on class, key, time and result" do
      metric = described_class.new(:search, true, 1696793204)
      expect(metric.hash).to eq([described_class, metric.key, metric.time, metric.result].hash)
    end
  end

  describe "#as_json" do
    it "returns key time and result" do
      metric = described_class.new(:search, true, 1696793160)
      expect(metric.as_json).to eq({
        "key" => "search",
        "result" => true,
        "time" => 1696793160,
      })
    end

    it "can include other hashes" do
      metric = described_class.new(:search, true, 1696793160)
      expect(metric.as_json(with: {"value" => 2})).to eq({
        "key" => "search",
        "result" => true,
        "time" => 1696793160,
        "value" => 2,
      })
    end
  end
end
