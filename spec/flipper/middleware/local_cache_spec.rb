require 'helper'
require 'rack/test'
require 'flipper/middleware/local_cache'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/memory'

describe Flipper::Middleware::LocalCache do
  include Rack::Test::Methods

  class Enum < Struct.new(:iter)
    def each(&block)
      iter.call(&block)
    end
  end

  let(:source)         { {} }
  let(:memory_adapter) { Flipper::Adapters::Memory.new(source) }
  let(:adapter)        { Flipper::Adapters::OperationLogger.new(memory_adapter) }
  let(:flipper)        { Flipper.new(adapter) }

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

  it "delegates" do
    called = false
    app = lambda { |env|
      called = true
      [200, {}, nil]
    }
    middleware = described_class.new app, flipper
    middleware.call({})
    called.should be_true
  end

  it "enables memoization during delegation" do
    app = lambda { |env|
      flipper.adapter.using_local_cache?.should be_true
      [200, {}, nil]
    }
    middleware = described_class.new app, flipper
    middleware.call({})
  end

  it "disables local cache after body close" do
    app = lambda { |env| [200, {}, []] }
    middleware = described_class.new app, flipper
    body = middleware.call({}).last

    flipper.adapter.using_local_cache?.should be_true
    body.close
    flipper.adapter.using_local_cache?.should be_false
  end

  it "clears local cache after body close" do
    app = lambda { |env| [200, {}, []] }
    middleware = described_class.new app, flipper
    body = middleware.call({}).last

    flipper.adapter.local_cache['hello'] = 'world'
    body.close
    flipper.adapter.local_cache.should be_empty
  end

  it "only performs one get per feature enabled check" do
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

    adapter.count(:get).should be(1)
  end

  context "with a successful request" do
    it "clears the local cache" do
      flipper.adapter.local_cache.should_receive(:clear).twice
      get '/'
    end
  end

  context "when the request raises an error" do
    it "clears the local cache" do
      flipper.adapter.local_cache.should_receive(:clear).once
      get '/fail' rescue nil
    end
  end
end
