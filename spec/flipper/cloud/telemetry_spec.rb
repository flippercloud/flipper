require 'flipper/cloud/telemetry'
require 'flipper/cloud/configuration'

RSpec.describe Flipper::Cloud::Telemetry do
  describe '#record_enabled' do
    it "increments in metric storage" do
      stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").to_return(status: 200)

      name = Flipper::Feature::InstrumentationName

      begin
        config = Flipper::Cloud::Configuration.new(token: "test")
        telemetry = described_class.new(config)
        telemetry.record(name, {
          operation: :enabled?,
          feature_name: :foo,
          result: true,
        })
        telemetry.record(name, {
          operation: :enabled?,
          feature_name: :foo,
          result: true,
        })
        telemetry.record(name, {
          operation: :enabled?,
          feature_name: :bar,
          result: true,
        })
        telemetry.record(name, {
          operation: :enabled?,
          feature_name: :baz,
          result: true,
        })
        telemetry.record(name, {
          operation: :enabled?,
          feature_name: :foo,
          result: false,
        })

        drained = telemetry.metric_storage.drain
        metrics_by_key = drained.keys.group_by(&:key)

        foo_true, foo_false = metrics_by_key["foo"].partition { |metric| metric.result }
        foo_true_sum = foo_true.map { |metric| drained[metric] }.sum
        expect(foo_true_sum).to be(2)
        foo_false_sum = foo_false.map { |metric| drained[metric] }.sum
        expect(foo_false_sum).to be(1)

        bar_true_sum = metrics_by_key["bar"].map { |metric| drained[metric] }.sum
        expect(bar_true_sum).to be(1)

        baz_true_sum = metrics_by_key["baz"].map { |metric| drained[metric] }.sum
        expect(baz_true_sum).to be(1)
      ensure
        telemetry.stop
      end
    end
  end
end
