require 'helper'
require 'flipper/adapters/http'
require 'flipper/adapters/pstore'
require 'flipper/spec/shared_adapter_specs'
require 'rack/handler/webrick'

FLIPPER_SPEC_API_PORT = ENV.fetch('FLIPPER_SPEC_API_PORT', 9001).to_i

RSpec.describe Flipper::Adapters::Http do
  context 'adapter' do
    subject { described_class.new(URI("http://localhost:#{FLIPPER_SPEC_API_PORT}")) }

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

    it_should_behave_like 'a flipper adapter'
  end

  describe 'configuration' do
    let(:uri) { 'http://app.com/mount-point' }
    subject { described_class.new(uri) }
    let(:feature) { flipper[:feature_panel] }

    before do
      stub_request(:get, %r{\Ahttp://app.com*}).to_return(body: fixture_file('feature.json'))

      described_class.configure do |c|
        c.headers = { 'X-Custom-Header' => 'foo' }
        c.basic_auth = { 'username' => 'password' }
        c.read_timeout = 100
        c.open_timeout = 40
      end
    end

    subject { described_class.new('http://app.com/mount-point') }

    it 'allows client to set request headers' do
      subject.get(feature)
      expect(
        a_request(:get, 'http://app.com/mount-point/api/v1/features/feature_panel')
        .with(headers: { 'X-Custom-Header' => 'foo' })
      ).to have_been_made.once
    end

    it 'allows client to set basic auth' do
      subject.get(feature)
      expect(
        a_request(:get, 'http://app.com/mount-point/api/v1/features/feature_panel')
        .with(basic_auth: %w(username password))
      ).to have_been_made.once
    end
  end

  def fixture_file(name)
    fixtures_path = File.expand_path('../../../fixtures', __FILE__)
    File.new(fixtures_path + '/' + name)
  end
end
