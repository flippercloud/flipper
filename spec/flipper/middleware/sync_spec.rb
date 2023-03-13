require 'rack/test'
require 'active_support/cache'
require 'flipper/adapters/active_support_cache_store'
require 'flipper/adapters/operation_logger'

RSpec.describe Flipper::Middleware::Sync do
  include Rack::Test::Methods

  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:adapter)        do
    Flipper::Adapters::OperationLogger.new(memory_adapter)
  end
  let(:env) { {} }
  let(:app) { lambda { |_env| [200, {}, nil] } }

  subject do
    described_class.new(app)
  end

  RSpec.shared_examples_for 'sync middleware' do
    it 'delegates to the app' do
      expect(app).to receive(:call).and_call_original
      subject.call(env)
    end

    it 'calls #sync around the request' do
      expect(flipper.adapter).to be_a(Flipper::Adapters::Poll)
      expect(flipper.adapter).to receive(:sync).and_yield
      subject.call(env)
    end
  end

  context 'when memoize: :poll' do
    let(:flipper) { Flipper.new(adapter, memoize: :poll) }

    context 'with Flipper setup in env' do
      let(:env) { { 'flipper' => flipper } }

      it_behaves_like 'sync middleware'
    end

    context 'defaults to Flipper' do
      before do
        Flipper.configure do |config|
          config.default { flipper }
        end
      end

      it_behaves_like 'sync middleware'
    end
  end

  context 'when memoize: false' do
    let(:flipper) { Flipper.new(adapter, memoize: false) }
    let(:env) { { 'flipper' => flipper } }

    it 'delegates to the app' do
      expect(app).to receive(:call).and_call_original
      subject.call(env)
    end
  end
end
