require "stringio"
require 'flipper/cloud/configuration'
require 'flipper/cloud/telemetry/submitter'

RSpec.describe Flipper::Cloud::Telemetry::Submitter do
  let(:cloud_configuration) {
    Flipper::Cloud::Configuration.new({token: "asdf"})
  }
  let(:fake_backoff_policy) { FakeBackoffPolicy.new }
  let(:subject) { described_class.new(cloud_configuration, backoff_policy: fake_backoff_policy) }

  describe "#initialize" do
    it "works with cloud_configuration" do
      submitter = described_class.new(cloud_configuration)
      expect(submitter.cloud_configuration).to eq(cloud_configuration)
    end
  end

  describe "#call" do
    let(:enabled_metrics) {
      {
        Flipper::Cloud::Telemetry::Metric.new(:search, true, 1696793160) => 10,
        Flipper::Cloud::Telemetry::Metric.new(:search, false, 1696793161) => 15,
        Flipper::Cloud::Telemetry::Metric.new(:plausible, true, 1696793162) => 25,
        Flipper::Cloud::Telemetry::Metric.new(:administrator, true, 1696793164) => 1,
        Flipper::Cloud::Telemetry::Metric.new(:administrator, false, 1696793164) => 24,
      }
    }

    it "does not submit blank metrics" do
      expect(subject.call({})).to be(nil)
    end

    it "submits present metrics" do
      expected_body = {
        "request_id" => subject.request_id,
        "enabled_metrics" =>[
          {"key" => "search", "time" => 1696793160, "result" => true, "value" => 10},
          {"key" => "search", "time" => 1696793160, "result" => false, "value" => 15},
          {"key" => "plausible", "time" => 1696793160, "result" => true, "value" => 25},
          {"key" => "administrator", "time" => 1696793160, "result" => true, "value" => 1},
          {"key" => "administrator", "time" => 1696793160, "result" => false, "value" => 24},
        ]
      }
      expected_headers = {
        'accept' => 'application/json',
        'client-engine' => defined?(RUBY_ENGINE) ? RUBY_ENGINE : "",
        'client-hostname' => Socket.gethostname,
        'client-language' => 'ruby',
        'client-language-version' => "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})",
        'client-pid' => Process.pid.to_s,
        'client-platform' => RUBY_PLATFORM,
        'client-thread' => Thread.current.object_id.to_s,
        'content-encoding' => 'gzip',
        'content-type' => 'application/json',
        'flipper-cloud-token' => 'asdf',
        'schema-version' => 'V1',
        'user-agent' => "Flipper HTTP Adapter v#{Flipper::VERSION}",
      }
      stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
        with(headers: expected_headers) { |request|
          gunzipped = Flipper::Typecast.from_gzip(request.body)
          body = Flipper::Typecast.from_json(gunzipped)
          body == expected_body
        }.to_return(status: 200, body: "{}")
      subject.call(enabled_metrics)
    end

    it "defaults backoff_policy" do
      stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
        to_return(status: 429, body: "{}").
        to_return(status: 200, body: "{}")
      instance = described_class.new(cloud_configuration)
      expect(instance.backoff_policy.min_timeout_ms).to eq(30_000)
      expect(instance.backoff_policy.max_timeout_ms).to eq(120_000)
    end

    it "tries 10 times by default" do
      stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
        to_return(status: 500, body: "{}")
      subject.call(enabled_metrics)
      expect(subject.backoff_policy.retries).to eq(4) # 4 retries + 1 initial attempt
    end

    [
      EOFError,
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::EINVAL,
      Errno::ENETUNREACH,
      Errno::ENOTSOCK,
      Errno::EPIPE,
      Errno::ETIMEDOUT,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Net::ReadTimeout,
      OpenSSL::SSL::SSLError,
      SocketError,
      Timeout::Error,  # Also covers subclasses like Net::OpenTimeout.
    ].each  do |error_class|
      it "retries on #{error_class}" do
        stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
          to_raise(error_class)
        subject.call(enabled_metrics)
        expect(subject.backoff_policy.retries).to eq(4)
      end
    end

    it "retries on 429" do
      stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
        to_return(status: 429, body: "{}").
        to_return(status: 429, body: "{}").
        to_return(status: 200, body: "{}")
      subject.call(enabled_metrics)
      expect(subject.backoff_policy.retries).to eq(2)
    end

    it "retries on 500" do
      stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
        to_return(status: 500, body: "{}").
        to_return(status: 503, body: "{}").
        to_return(status: 502, body: "{}").
        to_return(status: 200, body: "{}")
      subject.call(enabled_metrics)
      expect(subject.backoff_policy.retries).to eq(3)
    end
  end

  def with_telemetry_debug_logging(&block)
    output = StringIO.new
    original_logger = cloud_configuration.logger

    begin
      cloud_configuration.logger = Logger.new(output)
      block.call
    ensure
      cloud_configuration.logger = original_logger
    end

    output.string
  end
end
