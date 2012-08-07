require 'helper'
require 'rack/test'
require 'flipper/middleware/local_cache'

describe Flipper::Middleware::LocalCache do
  include Rack::Test::Methods

  class LoggedHash < Hash
    attr_reader :reads, :writes

    Read  = Struct.new(:key)
    Write = Struct.new(:key, :value)

    def initialize(*args)
      @reads, @writes = [], []
      super
    end

    def [](key)
      @reads << Read.new(key)
      super
    end

    def []=(key, value)
      @writes << Write.new(key, value)
      super
    end
  end

  class Enum < Struct.new(:iter)
    def each(&b)
      iter.call(&b)
    end
  end

  let(:source)  { LoggedHash.new }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }
  let(:flipper) { Flipper.new(adapter) }

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

  it "enables local cache for body each" do
    app = lambda { |env|
      [200, {}, Enum.new(lambda { |&b|
        flipper.adapter.using_local_cache?.should be_true
        b.call "hello"
      })]
    }
    middleware = described_class.new app, flipper
    body = middleware.call({}).last
    body.each { |x| x.should eql('hello') }
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

    flipper.adapter.local_cache.should_not be_empty
    body.close
    flipper.adapter.local_cache.should be_empty
  end

  it "really does cache" do
    flipper[:stats].enable

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

    source.reads.map(&:key).should eq(["stats/boolean"])
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
