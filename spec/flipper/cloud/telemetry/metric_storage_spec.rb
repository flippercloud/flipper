require 'flipper/cloud/telemetry/metric_storage'
require 'flipper/cloud/telemetry/metric'

RSpec.describe Flipper::Cloud::Telemetry::MetricStorage do
  describe "#increment" do
    it "increments the counter for the metric" do
      metric_storage = described_class.new
      storage = metric_storage.instance_variable_get(:@storage)
      metric = Flipper::Cloud::Telemetry::Metric.new(:search, true, 1696793160)
      other = Flipper::Cloud::Telemetry::Metric.new(:search, false, 1696793160)

      metric_storage.increment(metric)
      expect(storage[metric].value).to be(1)

      5.times { metric_storage.increment(metric) }
      expect(storage[metric].value).to be(6)

      metric_storage.increment(other)
      expect(storage[other].value).to be(1)
    end
  end

  describe "#drain" do
    it "returns clears metrics and return hash" do
      metric_storage = described_class.new
      storage = metric_storage.instance_variable_get(:@storage)
      storage[Flipper::Cloud::Telemetry::Metric.new(:search, true, 1696793160)] = Concurrent::AtomicFixnum.new(10)
      storage[Flipper::Cloud::Telemetry::Metric.new(:search, false, 1696793161)] = Concurrent::AtomicFixnum.new(15)
      storage[Flipper::Cloud::Telemetry::Metric.new(:plausible, true, 1696793162)] = Concurrent::AtomicFixnum.new(25)
      storage[Flipper::Cloud::Telemetry::Metric.new(:administrator, true, 1696793164)] = Concurrent::AtomicFixnum.new(1)
      storage[Flipper::Cloud::Telemetry::Metric.new(:administrator, false, 1696793164)] = Concurrent::AtomicFixnum.new(24)

      drained = metric_storage.drain
      expect(drained).to be_frozen
      expect(drained).to eq({
        Flipper::Cloud::Telemetry::Metric.new(:search, true, 1696793160) => 10,
        Flipper::Cloud::Telemetry::Metric.new(:search, false, 1696793161) => 15,
        Flipper::Cloud::Telemetry::Metric.new(:plausible, true, 1696793162) => 25,
        Flipper::Cloud::Telemetry::Metric.new(:administrator, true, 1696793164) => 1,
        Flipper::Cloud::Telemetry::Metric.new(:administrator, false, 1696793164) => 24,
      })
      expect(storage.keys).to eq([])
    end
  end

  describe "#empty?" do
    it "returns true if empty" do
      metric_storage = described_class.new
      expect(metric_storage).to be_empty
    end

    it "returns false if not empty" do
      metric_storage = described_class.new
      metric_storage.increment Flipper::Cloud::Telemetry::Metric.new(:search, true, 1696793160)
      expect(metric_storage).not_to be_empty
    end
  end
end
