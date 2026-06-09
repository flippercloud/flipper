require 'rack/test'
require 'flipper/adapters/operation_logger'

RSpec.describe Flipper::Middleware::Sync do
  include Rack::Test::Methods

  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:adapter) { Flipper::Adapters::OperationLogger.new(memory_adapter) }
  let(:app) { lambda { |_env| [200, {}, ['OK']] } }

  subject { described_class.new(app) }

  context 'when adapter responds to sync' do
    let(:flipper) { Flipper.new(adapter, memoize: :poll) }
    let(:env) { { 'flipper' => flipper } }

    it 'delegates to the app' do
      expect(app).to receive(:call).and_call_original
      subject.call(env)
    end

    it 'calls sync on the adapter' do
      expect(flipper.adapter).to receive(:sync).and_yield
      subject.call(env)
    end
  end

  context 'when adapter does not respond to sync' do
    let(:flipper) { Flipper.new(adapter, memoize: false) }
    let(:env) { { 'flipper' => flipper } }

    it 'delegates to the app without syncing' do
      expect(app).to receive(:call).and_call_original
      subject.call(env)
    end
  end

  context 'defaults to Flipper' do
    let(:flipper) { Flipper.new(adapter, memoize: :poll) }

    before do
      Flipper.configure do |config|
        config.default { flipper }
      end
    end

    it 'uses the default Flipper instance' do
      expect(flipper.adapter).to receive(:sync).and_yield
      subject.call({})
    end
  end
end
