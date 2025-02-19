require 'flipper/cloud/telemetry'
require 'flipper/cloud/configuration'

RSpec.describe Flipper::Cloud::Telemetry do
  before do
    # Stub polling for features.
    stub_request(:get, "https://www.flippercloud.io/adapter/features?exclude_gate_names=true").
      to_return(status: 200, body: "{}")
  end

  it "phones home and does not update telemetry interval if missing" do
    stub = stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
      to_return(status: 200, body: "{}")

    cloud_configuration = Flipper::Cloud::Configuration.new(token: "test")

    # Record some telemetry and stop the threads so we submit a response.
    telemetry = described_class.new(cloud_configuration)
    telemetry.record(Flipper::Feature::InstrumentationName, {
      operation: :enabled?,
      feature_name: :foo,
      result: true,
    })
    telemetry.stop

    expect(telemetry.interval).to eq(60)
    expect(telemetry.timer.execution_interval).to eq(60)
    expect(stub).to have_been_requested.at_least_once
  end

  it "phones home and updates telemetry interval if present" do
    stub = stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
      to_return(status: 200, body: "{}", headers: {"telemetry-interval" => "120"})

    cloud_configuration = Flipper::Cloud::Configuration.new(token: "test")

    # Record some telemetry and stop the threads so we submit a response.
    telemetry = described_class.new(cloud_configuration)
    telemetry.record(Flipper::Feature::InstrumentationName, {
      operation: :enabled?,
      feature_name: :foo,
      result: true,
    })
    telemetry.stop

    expect(telemetry.interval).to eq(120)
    expect(telemetry.timer.execution_interval).to eq(120)
    expect(stub).to have_been_requested.at_least_once
  end

  it "phones home and requests shutdown if telemetry-shutdown header is true" do
    stub = stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
      to_return(status: 404, body: "{}", headers: {"telemetry-shutdown" => "true"})

    output = StringIO.new
    cloud_configuration = Flipper::Cloud::Configuration.new(
      token: "test",
      logger: Logger.new(output),
      logging_enabled: true,
    )

    # Record some telemetry and stop the threads so we submit a response.
    telemetry = described_class.new(cloud_configuration)
    telemetry.record(Flipper::Feature::InstrumentationName, {
      operation: :enabled?,
      feature_name: :foo,
      result: true,
    })
    telemetry.stop
    expect(stub).to have_been_requested.at_least_once
    expect(output.string).to match(/action=telemetry_shutdown message=The server has requested that telemetry be shut down./)
  end

  it "phones home and does not shutdown if telemetry shutdown header is missing" do
    stub = stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
      to_return(status: 404, body: "{}", headers: {})

    output = StringIO.new
    cloud_configuration = Flipper::Cloud::Configuration.new(
      token: "test",
      logger: Logger.new(output),
      logging_enabled: true,
    )

    # Record some telemetry and stop the threads so we submit a response.
    telemetry = described_class.new(cloud_configuration)
    telemetry.record(Flipper::Feature::InstrumentationName, {
      operation: :enabled?,
      feature_name: :foo,
      result: true,
    })
    telemetry.stop
    expect(stub).to have_been_requested.at_least_once
    expect(output.string).not_to match(/action=telemetry_shutdown message=The server has requested that telemetry be shut down./)
  end

  it "can update telemetry interval from error" do
    stub = stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
      to_return(status: 500, body: "{}", headers: {"telemetry-interval" => "120"})

    cloud_configuration = Flipper::Cloud::Configuration.new(token: "test")
    telemetry = described_class.new(cloud_configuration)

    # Override the submitter to use back off policy that doesn't actually
    # sleep. If we don't then the stop below kills the working thread and the
    # interval is never updated.
    telemetry.submitter = ->(drained) {
      Flipper::Cloud::Telemetry::Submitter.new(
        cloud_configuration,
        backoff_policy: FakeBackoffPolicy.new
      ).call(drained)
    }

    # Record some telemetry and stop the threads so we submit a response.
    telemetry.record(Flipper::Feature::InstrumentationName, {
      operation: :enabled?,
      feature_name: :foo,
      result: true,
    })
    telemetry.stop

    # Check the conig interval and the timer interval.
    expect(telemetry.interval).to eq(120)
    expect(telemetry.timer.execution_interval).to eq(120)
    expect(stub).to have_been_requested.times(5)
  end

  it "doesn't try to update telemetry interval from error if not response error" do
    stub = stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
      to_raise(Net::OpenTimeout)

    cloud_configuration = Flipper::Cloud::Configuration.new(token: "test")
    telemetry = described_class.new(cloud_configuration)

    # Override the submitter to use back off policy that doesn't actually
    # sleep. If we don't then the stop below kills the working thread and the
    # interval is never updated.
    telemetry.submitter = ->(drained) {
      Flipper::Cloud::Telemetry::Submitter.new(
        cloud_configuration,
        backoff_policy: FakeBackoffPolicy.new
      ).call(drained)
    }

    # Record some telemetry and stop the threads so we submit a response.
    telemetry.record(Flipper::Feature::InstrumentationName, {
      operation: :enabled?,
      feature_name: :foo,
      result: true,
    })
    telemetry.stop

    expect(telemetry.interval).to eq(60)
    expect(telemetry.timer.execution_interval).to eq(60)
    expect(stub).to have_been_requested.times(5)
  end

  describe '#record' do
    it "increments in metric storage" do
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
