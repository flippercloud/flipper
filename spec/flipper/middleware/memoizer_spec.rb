require 'helper'
require 'rack/test'
require 'flipper/middleware/memoizer'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/memory'

RSpec.describe Flipper::Middleware::Memoizer do
  include Rack::Test::Methods

  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:adapter)        do
    Flipper::Adapters::OperationLogger.new(memory_adapter)
  end
  let(:flipper) { Flipper.new(adapter) }

  after do
    flipper.storage.memoize = nil
  end

  RSpec.shared_examples_for 'flipper middleware' do
    it 'delegates' do
      called = false
      app = lambda do |_env|
        called = true
        [200, {}, nil]
      end
      middleware = described_class.new app, flipper
      middleware.call({})
      expect(called).to eq(true)
    end

    it 'disables local cache after body close' do
      app = ->(_env) { [200, {}, []] }
      middleware = described_class.new app, flipper
      body = middleware.call({}).last

      expect(flipper.storage.memoizing?).to eq(true)
      body.close
      expect(flipper.storage.memoizing?).to eq(false)
    end

    it 'clears local cache after body close' do
      app = ->(_env) { [200, {}, []] }
      middleware = described_class.new app, flipper
      body = middleware.call({}).last

      flipper.storage.cache['hello'] = 'world'
      body.close
      expect(flipper.storage.cache).to be_empty
    end

    it "clears the local cache with a successful request" do
      flipper.storage.cache['hello'] = 'world'
      get '/'
      expect(flipper.storage.cache).to be_empty
    end

    it "clears the local cache even when the request raises an error" do
      flipper.storage.cache['hello'] = 'world'
      begin
        get '/fail'
      rescue
        nil
      end
      expect(flipper.storage.cache).to be_empty
    end

    it 'caches getting a feature for duration of request' do
      flipper[:stats].enable

      # clear the log of operations
      adapter.reset

      app = lambda do |_env|
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        [200, {}, []]
      end

      middleware = described_class.new app, flipper
      middleware.call({})

      expect(adapter.count(:get)).to be(1)
    end
  end

  context 'with flipper instance' do
    let(:app) do
      # ensure scoped for builder block, annoying...
      instance = flipper
      middleware = described_class

      Rack::Builder.new do
        use middleware, instance

        map '/' do
          run ->(_env) { [200, {}, []] }
        end

        map '/fail' do
          run ->(_env) { raise 'FAIL!' }
        end
      end.to_app
    end

    include_examples 'flipper middleware'
  end

  context 'with preload_all' do
    let(:app) do
      # ensure scoped for builder block, annoying...
      instance = flipper
      middleware = described_class

      Rack::Builder.new do
        use middleware, instance, preload_all: true

        map '/' do
          run ->(_env) { [200, {}, []] }
        end

        map '/fail' do
          run ->(_env) { raise 'FAIL!' }
        end
      end.to_app
    end

    include_examples 'flipper middleware'

    it 'eagerly caches known features for duration of request' do
      flipper[:stats].enable
      flipper[:shiny].enable

      # clear the log of operations
      adapter.reset

      app = lambda do |_env|
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        flipper[:shiny].enabled?
        flipper[:shiny].enabled?
        [200, {}, []]
      end

      middleware = described_class.new app, flipper, preload_all: true
      middleware.call({})

      expect(adapter.count(:features)).to be(1)
      expect(adapter.count(:get_multi)).to be(1)
      expect(adapter.last(:get_multi).args).to eq([[flipper[:stats], flipper[:shiny]]])
    end

    it 'caches unknown features for duration of request' do
      # clear the log of operations
      adapter.reset

      app = lambda do |_env|
        flipper[:other].enabled?
        flipper[:other].enabled?
        [200, {}, []]
      end

      middleware = described_class.new app, flipper, preload_all: true
      middleware.call({})

      expect(adapter.count(:get)).to be(1)
      expect(adapter.last(:get).args).to eq([flipper[:other]])
    end
  end

  context 'with preload specific' do
    let(:app) do
      # ensure scoped for builder block, annoying...
      instance = flipper
      middleware = described_class

      Rack::Builder.new do
        use middleware, instance, preload: %i(stats)

        map '/' do
          run ->(_env) { [200, {}, []] }
        end

        map '/fail' do
          run ->(_env) { raise 'FAIL!' }
        end
      end.to_app
    end

    include_examples 'flipper middleware'

    it 'eagerly caches specified features for duration of request' do
      # clear the log of operations
      adapter.reset

      app = lambda do |_env|
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        flipper[:shiny].enabled?
        flipper[:shiny].enabled?
        [200, {}, []]
      end

      middleware = described_class.new app, flipper, preload: %i(stats)
      middleware.call({})

      expect(adapter.count(:get_multi)).to be(1)
      expect(adapter.last(:get_multi).args).to eq([[flipper[:stats]]])
    end

    it 'caches unknown features for duration of request' do
      # clear the log of operations
      adapter.reset

      app = lambda do |_env|
        flipper[:other].enabled?
        flipper[:other].enabled?
        [200, {}, []]
      end

      middleware = described_class.new app, flipper, preload: %i(stats)
      middleware.call({})

      expect(adapter.count(:get)).to be(1)
      expect(adapter.last(:get).args).to eq([flipper[:other]])
    end
  end

  context 'when an app raises an exception' do
    it 'resets memoize' do
      begin
        app = ->(_env) { raise }
        middleware = described_class.new app, flipper
        middleware.call({})
      rescue RuntimeError
        expect(flipper.storage.memoizing?).to be(false)
      end
    end
  end

  context 'with block that yields flipper instance' do
    let(:app) do
      # ensure scoped for builder block, annoying...
      instance = flipper
      middleware = described_class

      Rack::Builder.new do
        use middleware, -> { instance }

        map '/' do
          run ->(_env) { [200, {}, []] }
        end

        map '/fail' do
          run ->(_env) { raise 'FAIL!' }
        end
      end.to_app
    end

    include_examples 'flipper middleware'
  end
end
