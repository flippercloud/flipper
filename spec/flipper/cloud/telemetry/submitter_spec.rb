require "stringio"
require 'flipper/cloud/configuration'
require 'flipper/cloud/telemetry/submitter'

RSpec.describe Flipper::Cloud::Telemetry::Submitter do
  let(:cloud_configuration) {
    Flipper::Cloud::Configuration.new({token: "asdf"})
  }

  let(:subject) { described_class.new(cloud_configuration) }

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
        'Accept' => 'application/json',
        'Client-Engine' => defined?(RUBY_ENGINE) ? RUBY_ENGINE : "",
        'Client-Hostname' => Socket.gethostname,
        'Client-Language' => 'ruby',
        'Client-Language-Version' => "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})",
        'Client-Pid' => Process.pid.to_s,
        'Client-Platform' => RUBY_PLATFORM,
        'Client-Thread' => Thread.current.object_id.to_s,
        'Content-Encoding' => 'gzip',
        'Content-Type' => 'application/json',
        'Flipper-Cloud-Token' => 'asdf',
        'Schema-Version' => 'V1',
        'User-Agent' => "Flipper HTTP Adapter v#{Flipper::VERSION}",
      }
      stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
        with { |request|
          gunzipped = Flipper::Typecast.from_gzip(request.body)
          body = Flipper::Typecast.from_json(gunzipped)
          body == expected_body && request.headers == expected_headers
        }.to_return(status: 200, body: "{}", headers: {})
      subject.call(enabled_metrics)
    end

    it "retries on 429" do
      output = StringIO.new
      cloud_configuration.telemetry_logger = Logger.new(output)
      with_env "FLIPPER_CLOUD_TELEMETRY_LOGGING" => "true" do
        stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
          to_return(status: 429, body: "{}", headers: {}).
          to_return(status: 429, body: "{}", headers: {}).
          to_return(status: 200, body: "{}", headers: {})
        subject.call(enabled_metrics)
        expect(output.string).to include("retrying=true retries_remaining=10")
        expect(output.string).to include("retrying=true retries_remaining=9")
        expect(output.string).not_to include("retrying=true retries_remaining=8")
      end
    end

    it "retries on 500" do
      output = StringIO.new
      cloud_configuration.telemetry_logger = Logger.new(output)
      with_env "FLIPPER_CLOUD_TELEMETRY_LOGGING" => "true" do
        stub_request(:post, "https://www.flippercloud.io/adapter/telemetry").
          to_return(status: 500, body: "{}", headers: {}).
          to_return(status: 503, body: "{}", headers: {}).
          to_return(status: 502, body: "{}", headers: {}).
          to_return(status: 200, body: "{}", headers: {})
        subject.call(enabled_metrics)
        expect(output.string).to include("retrying=true retries_remaining=10")
        expect(output.string).to include("retrying=true retries_remaining=9")
        expect(output.string).to include("retrying=true retries_remaining=8")
        expect(output.string).not_to include("retrying=true retries_remaining=7")
      end
    end
  end
end
