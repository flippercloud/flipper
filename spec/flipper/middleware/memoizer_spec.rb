require 'helper'
require 'rack/test'
require 'flipper/middleware/memoizer'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/memory'

RSpec.describe Flipper::Middleware::Memoizer do
  include Rack::Test::Methods

  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:adapter)        {
    Flipper::Adapters::OperationLogger.new(memory_adapter)
  }
  let(:flipper)        { Flipper.new(adapter) }

  after do
    flipper.adapter.memoize = nil
  end

  RSpec.shared_examples_for "flipper middleware" do
    it "delegates" do
      called = false
      app = lambda { |env|
        called = true
        [200, {}, nil]
      }
      middleware = described_class.new app, flipper
      middleware.call({})
      expect(called).to eq(true)
    end

    it "disables local cache after body close" do
      app = lambda { |env| [200, {}, []] }
      middleware = described_class.new app, flipper
      body = middleware.call({}).last

      expect(flipper.adapter.memoizing?).to eq(true)
      body.close
      expect(flipper.adapter.memoizing?).to eq(false)
    end

    it "clears local cache after body close" do
      app = lambda { |env| [200, {}, []] }
      middleware = described_class.new app, flipper
      body = middleware.call({}).last

      flipper.adapter.cache['hello'] = 'world'
      body.close
      expect(flipper.adapter.cache).to be_empty
    end

    it "clears the local cache with a successful request" do
      flipper.adapter.cache['hello'] = 'world'
      get '/'
      expect(flipper.adapter.cache).to be_empty
    end

    it "clears the local cache even when the request raises an error" do
      flipper.adapter.cache['hello'] = 'world'
      get '/fail' rescue nil
      expect(flipper.adapter.cache).to be_empty
    end

    it "caches getting a feature for duration of request" do
      flipper[:stats].enable

      # clear the log of operations
      adapter.reset

      app = lambda { |env|
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        flipper[:stats].enabled?
        [200, {}, []]
      }

      middleware = described_class.new app, flipper
      middleware.call({})

      expect(adapter.count(:get)).to be(1)
    end
  end

  context "with flipper instance" do
    let(:app) {
      # ensure scoped for builder block, annoying...
      instance = flipper
      middleware = described_class

      Rack::Builder.new do
        use middleware, instance

        map "/" do
          run lambda {|env| [200, {}, []] }
        end

        map "/fail" do
          run lambda {|env| raise "FAIL!" }
        end
      end.to_app
    }

    include_examples "flipper middleware"
  end

  context "with block that yields flipper instance" do
    let(:app) {
      # ensure scoped for builder block, annoying...
      instance = flipper
      middleware = described_class

      Rack::Builder.new do
        use middleware, lambda { instance }

        map "/" do
          run lambda {|env| [200, {}, []] }
        end

        map "/fail" do
          run lambda {|env| raise "FAIL!" }
        end
      end.to_app
    }

    include_examples "flipper middleware"
  end
end
