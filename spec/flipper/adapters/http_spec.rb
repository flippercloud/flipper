require 'flipper/adapters/http'
require 'flipper/adapters/pstore'

rack_handler = begin
  # Rack 3+
  require 'rackup/handler/webrick'
  Rackup::Handler::WEBrick
rescue LoadError
  require 'rack/handler/webrick'
  Rack::Handler::WEBrick
end


FLIPPER_SPEC_API_PORT = ENV.fetch('FLIPPER_SPEC_API_PORT', 9001).to_i

RSpec.describe Flipper::Adapters::Http do
  default_options = {
    url: "http://localhost:#{FLIPPER_SPEC_API_PORT}",
  }

  {
    basic: default_options.dup,
    gzip: default_options.dup.merge(headers: { 'accept-encoding': 'gzip' }),
  }.each do |name, options|
    context "adapter (#{name} #{options.inspect})" do
      subject do
        described_class.new(options)
      end

      before :all do
        @started = false
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
        @server.mount '/', rack_handler, app

        Thread.new { @server.start }
        Timeout.timeout(1) { :wait until @started }
      end

      after :all do
        @server.shutdown if @server
      end

      before(:each) do
        @pstore_file.unlink if @pstore_file.exist?
      end

      it_should_behave_like 'a flipper adapter'

      it "can enable and disable unregistered group" do
        flipper = Flipper.new(subject)
        expect(flipper[:search].enable_group(:some_made_up_group)).to be(true)
        expect(flipper[:search].groups_value).to eq(Set["some_made_up_group"])

        expect(flipper[:search].disable_group(:some_made_up_group)).to be(true)
        expect(flipper[:search].groups_value).to eq(Set.new)
      end

      it "can import" do
        adapter = Flipper::Adapters::Memory.new
        source_flipper = Flipper.new(adapter)
        source_flipper.enable_percentage_of_actors :search, 10
        source_flipper.enable_percentage_of_time :search, 15
        source_flipper.enable_actor :search, Flipper::Actor.new('User;1')
        source_flipper.enable_actor :search, Flipper::Actor.new('User;100')
        source_flipper.enable_group :search, :admins
        source_flipper.enable_group :search, :employees
        source_flipper.enable :plausible
        source_flipper.disable :google_analytics

        flipper = Flipper.new(subject)
        flipper.import(source_flipper)
        expect(flipper[:search].percentage_of_actors_value).to be(10)
        expect(flipper[:search].percentage_of_time_value).to be(15)
        expect(flipper[:search].actors_value).to eq(Set["User;1", "User;100"])
        expect(flipper[:search].groups_value).to eq(Set["admins", "employees"])
        expect(flipper[:plausible].boolean_value).to be(true)
        expect(flipper[:google_analytics].boolean_value).to be(false)
      end
    end
  end

  it "sends default headers" do
    headers = {
      'accept' => 'application/json',
      'content-type' => 'application/json',
      'user-agent' => "Flipper HTTP Adapter v#{Flipper::VERSION}",
    }
    stub_request(:get, "http://app.com/flipper/features/feature_panel")
      .with(headers: headers)
      .to_return(status: 404)

    adapter = described_class.new(url: 'http://app.com/flipper')
    adapter.get(flipper[:feature_panel])
  end

  it "sends framework versions" do
    stub_const("Rails", double(version: "7.1.0"))
    stub_const("Sinatra::VERSION", "3.1.0")
    stub_const("Hanami::VERSION", "0.7.2")
    stub_const("GoodJob::VERSION", "3.21.5")
    stub_const("Sidekiq::VERSION", "7.2.0")

    headers = {
      "client-framework" => [
        "rails=7.1.0",
        "sinatra=3.1.0",
        "hanami=0.7.2",
        "good_job=3.21.5",
        "sidekiq=7.2.0",
      ]
    }

    stub_request(:get, "http://app.com/flipper/features/feature_panel")
      .with(headers: headers)
      .to_return(status: 404)

    adapter = described_class.new(url: 'http://app.com/flipper')
    adapter.get(flipper[:feature_panel])
  end

  it "does not send undefined framework versions" do
    stub_const("Rails", double(version: "7.1.0"))
    stub_const("Sinatra::VERSION", "3.1.0")

    headers = {
      "client-framework" => ["rails=7.1.0", "sinatra=3.1.0"]
    }

    stub_request(:get, "http://app.com/flipper/features/feature_panel")
      .with(headers: headers)
      .to_return(status: 404)

    adapter = described_class.new(url: 'http://app.com/flipper')
    adapter.get(flipper[:feature_panel])
  end


  describe "#get" do
    it "raises error when not successful response" do
      stub_request(:get, "http://app.com/flipper/features/feature_panel")
        .to_return(status: 503)

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.get(flipper[:feature_panel])
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#get_multi" do
    it "raises error when not successful response" do
      stub_request(:get, "http://app.com/flipper/features?keys=feature_panel&exclude_gate_names=true")
        .to_return(status: 503)

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.get_multi([flipper[:feature_panel]])
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#get_all" do
    it "raises error when not successful response" do
      stub_request(:get, "http://app.com/flipper/features?exclude_gate_names=true")
        .to_return(status: 503)

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.get_all
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#features" do
    it "raises error when not successful response" do
      stub_request(:get, "http://app.com/flipper/features?exclude_gate_names=true")
        .to_return(status: 503)

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.features
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#add" do
    it "raises error when not successful" do
      stub_request(:post, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.add(Flipper::Feature.new(:search, adapter))
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#remove" do
    it "raises error when not successful" do
      stub_request(:delete, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.remove(Flipper::Feature.new(:search, adapter))
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#clear" do
    it "raises error when not successful" do
      stub_request(:delete, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.clear(Flipper::Feature.new(:search, adapter))
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#enable" do
    it "raises error when not successful" do
      stub_request(:post, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
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

      adapter = described_class.new(url: 'http://app.com/flipper')
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

      adapter = described_class.new(url: 'http://app.com/flipper')
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

      adapter = described_class.new(url: 'http://app.com/flipper')
      feature = Flipper::Feature.new(:search, adapter)
      gate = feature.gate(:boolean)
      thing = gate.wrap(false)
      expect {
        adapter.disable(feature, gate, thing)
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe 'configuration' do
    let(:debug_output) { object_double($stderr) }
    let(:options) do
      {
        url: 'http://app.com/mount-point',
        headers: { 'x-custom-header' => 'foo' },
        basic_auth_username: 'username',
        basic_auth_password: 'password',
        read_timeout: 100,
        open_timeout: 40,
        write_timeout: 40,
        debug_output: debug_output,
      }
    end
    subject { described_class.new(options) }
    let(:feature) { flipper[:feature_panel] }

    before do
      stub_request(:get, %r{\Ahttp://app.com*}).
        to_return(body: fixture_file('feature.json'))
    end

    it 'allows client to set request headers' do
      subject.get(feature)
      expect(
        a_request(:get, 'http://app.com/mount-point/features/feature_panel')
        .with(headers: { 'x-custom-header' => 'foo' })
      ).to have_been_made.once
    end

    it 'allows client to set basic auth' do
      subject.get(feature)
      expect(
        a_request(:get, 'http://app.com/mount-point/features/feature_panel')
        .with(basic_auth: %w(username password))
      ).to have_been_made.once
    end

    it 'allows client to set debug output' do
      user_agent = Net::HTTP.new("app.com")
      allow(Net::HTTP).to receive(:new).and_return(user_agent)

      expect(user_agent).to receive(:set_debug_output).with(debug_output)
      subject.get(feature)
    end
  end

  def fixture_file(name)
    fixtures_path = File.expand_path('../../../fixtures', __FILE__)
    File.new(fixtures_path + '/' + name)
  end
end
