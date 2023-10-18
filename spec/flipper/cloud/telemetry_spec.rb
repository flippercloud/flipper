require 'flipper/cloud/telemetry'
require 'flipper/cloud/configuration'

RSpec.describe Flipper::Cloud::Telemetry do
  describe '#record_enabled' do
    it "increments in metric storage" do
      stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").to_return(status: 200)

      begin
        config = Flipper::Cloud::Configuration.new(token: "test")
        telemetry = described_class.new(config)
        telemetry.record(Flipper::Feature::InstrumentationName, {
          operation: :enabled?,
          feature_name: :foo,
          result: true,
        })
        telemetry.record(Flipper::Feature::InstrumentationName, {
          operation: :enabled?,
          feature_name: :foo,
          result: true,
        })
        telemetry.record(Flipper::Feature::InstrumentationName, {
          operation: :enabled?,
          feature_name: :bar,
          result: true,
        })
        telemetry.record(Flipper::Feature::InstrumentationName, {
          operation: :enabled?,
          feature_name: :baz,
          result: true,
        })
        telemetry.record(Flipper::Feature::InstrumentationName, {
          operation: :enabled?,
          feature_name: :foo,
          result: false,
        })

        drained = telemetry.metric_storage.drain

        foo_true_sum = drained.keys.select { |metric| metric.key == "foo" }.select { |metric| metric.result }.map { |metric| drained[metric] }.sum
        expect(foo_true_sum).to be(2)

        foo_false_sum = drained.keys.select { |metric| metric.key == "foo" }.select { |metric| !metric.result }.map { |metric| drained[metric] }.sum
        expect(foo_false_sum).to be(1)
      ensure
        telemetry.stop
      end
    end
  end
end
