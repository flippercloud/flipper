require 'flipper/adapters/http_read_async'
require 'flipper/adapters/pstore'
require 'rack/handler/webrick'

FLIPPER_SPEC_API_PORT = ENV.fetch('FLIPPER_SPEC_API_PORT', 9001).to_i

RSpec.describe Flipper::Adapters::HttpReadAsync do
  let(:default_options) {
    {
      worker: {logger: Logger.new("/dev/null")},
    }
  }
  context 'adapter' do
    subject do
      described_class.new(default_options.merge(url: "http://localhost:#{FLIPPER_SPEC_API_PORT}"))
    end

    before :all do
      dir = FlipperRoot.join('tmp').tap(&:mkpath)
      log_path = dir.join('flipper_adapters_http_spec.log')
      @pstore_file = dir.join('flipper.pstore')
      @pstore_file.unlink if @pstore_file.exist?

      api_adapter = Flipper::Adapters::PStore.new(@pstore_file)
      flipper_api = Flipper.new(api_adapter)
      app = Flipper::Api.app(flipper_api)
      server_options = {
        Port: FLIPPER_SPEC_API_PORT,
        StartCallback: -> { @started = true },
        Logger: WEBrick::Log.new(log_path.to_s, WEBrick::Log::INFO),
        AccessLog: [
          [log_path.open('w'), WEBrick::AccessLog::COMBINED_LOG_FORMAT],
        ],
      }
      @server = WEBrick::HTTPServer.new(server_options)
      @server.mount '/', Rack::Handler::WEBrick, app

      Thread.new { @server.start }
      Timeout.timeout(1) { :wait until @started }
    end

    after :all do
      @server.shutdown if @server
    end

    before(:each) do
      @pstore_file.unlink if @pstore_file.exist?
    end

    after(:each) do
      subject.instance_variable_get("@worker").stop
    end

    it_should_behave_like 'a flipper adapter'

    it "works" do
      async_http = described_class.new(default_options.merge({
        url: "http://localhost:#{FLIPPER_SPEC_API_PORT}",
        interval: 1,
      }))
      sync_http = subject.instance_variable_get("@http_adapter")
      expect(sync_http).not_to be(nil)
      async_flipper = Flipper.new(async_http)
      sync_flipper = Flipper.new(sync_http)

      sync_flipper.enable_actor :foo, Flipper::Actor.new("User;1")
      sync_flipper.enable_group :foo, :admins

      sleep 2 # longer than the interval

      expect(async_http.get_all).to eq({
        "foo" => {
          boolean: nil,
          actors: Set["User;1"],
          groups: Set["admins"],
          percentage_of_actors: nil,
          percentage_of_time: nil,
        }
      })
    end
  end

  describe "#add" do
    it "raises error when not successful" do
      stub_request(:post, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(default_options.merge(url: 'http://app.com/flipper'))
      expect {
        adapter.add(Flipper::Feature.new(:search, adapter))
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#remove" do
    it "raises error when not successful" do
      stub_request(:delete, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(default_options.merge(url: 'http://app.com/flipper'))
      expect {
        adapter.remove(Flipper::Feature.new(:search, adapter))
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#clear" do
    it "raises error when not successful" do
      stub_request(:delete, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(default_options.merge(url: 'http://app.com/flipper'))
      expect {
        adapter.clear(Flipper::Feature.new(:search, adapter))
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#enable" do
    it "raises error when not successful" do
      stub_request(:post, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(default_options.merge(url: 'http://app.com/flipper'))
      feature = Flipper::Feature.new(:search, adapter)
      gate = feature.gate(:boolean)
      thing = gate.wrap(true)
      expect {
        adapter.enable(feature, gate, thing)
      }.to raise_error(Flipper::Adapters::Http::Error, "Failed with status: 503")
    end

    it "doesn't raise json error if body cannot be parsed" do
      stub_request(:post, /app.com/)
        .to_return(status: 503, body: "barf", headers: {})

      adapter = described_class.new(default_options.merge(url: 'http://app.com/flipper'))
      feature = Flipper::Feature.new(:search, adapter)
      gate = feature.gate(:boolean)
      thing = gate.wrap(true)
      expect {
        adapter.enable(feature, gate, thing)
      }.to raise_error(Flipper::Adapters::Http::Error)
    end

    it "includes response information if available when raising error" do
      api_response = {
        "code" => "error",
        "message" => "This feature has reached the limit to the number of " +
                     "actors per feature. Check out groups as a more flexible " +
                     "way to enable many actors.",
        "more_info" => "https://www.flippercloud.io/docs",
      }
      stub_request(:post, /app.com/)
        .to_return(status: 503, body: JSON.dump(api_response), headers: {})

      adapter = described_class.new(default_options.merge(url: 'http://app.com/flipper'))
      feature = Flipper::Feature.new(:search, adapter)
      gate = feature.gate(:boolean)
      thing = gate.wrap(true)
      error_message = "Failed with status: 503\n\nThis feature has reached the " +
                      "limit to the number of actors per feature. Check out " +
                      "groups as a more flexible way to enable many actors.\n" +
                      "https://www.flippercloud.io/docs"
      expect {
        adapter.enable(feature, gate, thing)
      }.to raise_error(Flipper::Adapters::Http::Error, error_message)
    end
  end

  describe "#disable" do
    it "raises error when not successful" do
      stub_request(:delete, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(default_options.merge(url: 'http://app.com/flipper'))
      feature = Flipper::Feature.new(:search, adapter)
      gate = feature.gate(:boolean)
      thing = gate.wrap(false)
      expect {
        adapter.disable(feature, gate, thing)
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end
end
