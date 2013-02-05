require 'helper'
require 'flipper/adapter'
require 'flipper/adapters/memory'
require 'flipper/instrumenters/memory'

describe Flipper::Adapter do
  let(:local_cache)  { {} }
  let(:adapter)      { Flipper::Adapters::Memory.new }
  let(:features_key) { described_class::FeaturesKey }

  subject { described_class.new(adapter, :local_cache => local_cache) }

  describe ".wrap" do
    context "with Flipper::Adapter instance" do
      before do
        @result = described_class.wrap(subject)
      end

      it "returns same Flipper::Adapter instance" do
        @result.should equal(subject)
      end

      it "wraps adapter that instance was wrapping" do
        @result.adapter.should be(subject.adapter)
      end
    end

    context "with adapter instance" do
      before do
        @result = described_class.wrap(adapter)
      end

      it "returns Flipper::Adapter instance" do
        @result.should be_instance_of(described_class)
      end

      it "wraps adapter" do
        @result.adapter.should be(adapter)
      end
    end

    context "with adapter instance and options" do
      let(:instrumenter) { double('Instrumentor') }

      before do
        @result = described_class.wrap(adapter, :instrumenter => instrumenter)
      end

      it "returns Flipper::Adapter instance" do
        @result.should be_instance_of(described_class)
      end

      it "wraps adapter" do
        @result.adapter.should be(adapter)
      end

      it "passes options to initialization" do
        @result.instrumenter.should be(instrumenter)
      end
    end
  end

  describe "#initialize" do
    it "sets adapter" do
      instance = described_class.new(adapter)
      instance.adapter.should be(adapter)
    end

    it "sets adapter name" do
      instance = described_class.new(adapter)
      instance.name.should be(:memory)
    end

    it "defaults instrumenter" do
      instance = described_class.new(adapter)
      instance.instrumenter.should be(Flipper::Instrumenters::Noop)
    end

    it "allows overriding instrumenter" do
      instrumenter = double('Instrumentor', :instrument => nil)
      instance = described_class.new(adapter, :instrumenter => instrumenter)
      instance.instrumenter.should be(instrumenter)
    end
  end

  describe "#use_local_cache=" do
    it "sets value" do
      subject.use_local_cache = true
      subject.using_local_cache?.should be_true

      subject.use_local_cache = false
      subject.using_local_cache?.should be_false
    end

    it "clears the local cache" do
      local_cache.should_receive(:clear)
      subject.use_local_cache = true
    end
  end

  describe "#using_local_cache?" do
    it "returns true if enabled" do
      subject.use_local_cache = true
      subject.using_local_cache?.should be_true
    end

    it "returns false if disabled" do
      subject.use_local_cache = false
      subject.using_local_cache?.should be_false
    end
  end

  context "with local cache enabled" do
    before do
      subject.use_local_cache = true
    end

    describe "#read" do
      before do
        adapter.write 'foo', 'bar'
        @result = subject.read('foo')
      end

      it "returns result of adapter read" do
        @result.should eq('bar')
      end

      it "memoizes adapter read value" do
        local_cache['foo'].should eq('bar')
        adapter.should_not_receive(:read)
        subject.read('foo').should eq('bar')
      end
    end

    describe "#set_members" do
      before do
        adapter.write 'foo', Set['1', '2']
        @result = subject.set_members('foo')
      end

      it "returns result of adapter set members" do
        @result.should eq(Set['1', '2'])
      end

      it "memoizes key" do
        local_cache['foo'].should eq(Set['1', '2'])
        adapter.should_not_receive(:set_members)
        subject.set_members('foo').should eq(Set['1', '2'])
      end
    end

    describe "#write" do
      before do
        subject.write 'foo', 'swanky'
      end

      it "performs adapter write" do
        adapter.read('foo').should eq('swanky')
      end

      it "unmemoizes key" do
        local_cache.key?('foo').should be_false
      end
    end

    describe "#delete" do
      before do
        adapter.write 'foo', 'bar'
        subject.delete 'foo'
      end

      it "performs adapter delete" do
        adapter.read('foo').should be_nil
      end

      it "unmemoizes key" do
        local_cache.key?('foo').should be_false
      end
    end

    describe "#set_add" do
      before do
        adapter.write 'foo', Set['1']
        local_cache['foo'] = Set['1']
        subject.set_add 'foo', '2'
      end

      it "returns result of adapter set members" do
        adapter.set_members('foo').should eq(Set['1', '2'])
      end

      it "unmemoizes key" do
        local_cache.key?('foo').should be_false
      end
    end

    describe "#set_delete" do
      before do
        adapter.write 'foo', Set['1', '2', '3']
        local_cache['foo'] = Set['1', '2', '3']
        subject.set_delete 'foo', '3'
      end

      it "returns result of adapter set members" do
        adapter.set_members('foo').should eq(Set['1', '2'])
      end

      it "unmemoizes key" do
        local_cache.key?('foo').should be_false
      end
    end
  end

  context "with local cache disabled" do
    before do
      subject.use_local_cache = false
    end

    describe "#read" do
      before do
        adapter.write 'foo', 'bar'
        @result = subject.read('foo')
      end

      it "returns result of adapter read" do
        @result.should eq('bar')
      end

      it "does not memoize adapter read value" do
        local_cache.key?('foo').should be_false
      end
    end

    describe "#set_members" do
      before do
        adapter.write 'foo', Set['1', '2']
        @result = subject.set_members('foo')
      end

      it "returns result of adapter set members" do
        @result.should eq(Set['1', '2'])
      end

      it "does not memoize the adapter set member result" do
        local_cache.key?('foo').should be_false
      end
    end

    describe "#write" do
      before do
        adapter.write 'foo', 'bar'
        local_cache['foo'] = 'bar'
        subject.write 'foo', 'swanky'
      end

      it "performs adapter write" do
        adapter.read('foo').should eq('swanky')
      end

      it "does not attempt to delete local cache key" do
        local_cache.key?('foo').should be_true
      end
    end

    describe "#delete" do
      before do
        adapter.write 'foo', 'bar'
        local_cache['foo'] = 'bar'
        subject.delete 'foo'
      end

      it "performs adapter delete" do
        adapter.read('foo').should be_nil
      end

      it "does not attempt to delete local cache key" do
        local_cache.key?('foo').should be_true
      end
    end

    describe "#set_add" do
      before do
        adapter.write 'foo', Set['1']
        local_cache['foo'] = Set['1']
        subject.set_add 'foo', '2'
      end

      it "performs adapter set add" do
        adapter.set_members('foo').should eq(Set['1', '2'])
      end

      it "does not attempt to delete local cache key" do
        local_cache.key?('foo').should be_true
      end
    end

    describe "#set_delete" do
      before do
        adapter.write 'foo', Set['1', '2', '3']
        local_cache['foo'] = Set['1', '2', '3']
        subject.set_delete 'foo', '3'
      end

      it "performs adapter set delete" do
        adapter.set_members('foo').should eq(Set['1', '2'])
      end

      it "does not attempt to delete local cache key" do
        local_cache.key?('foo').should be_true
      end
    end
  end

  describe "#eql?" do
    it "returns true for same class and adapter" do
      subject.eql?(described_class.new(adapter)).should be_true
    end

    it "returns false for different adapter" do
      instance = described_class.new(Flipper::Adapters::Memory.new)
      subject.eql?(instance).should be_false
    end

    it "returns false for different class" do
      subject.eql?(Object.new).should be_false
    end

    it "is aliased to ==" do
      (subject == described_class.new(adapter)).should be_true
    end
  end

  describe "#features" do
    context "with no features enabled/disabled" do
      it "defaults to empty set" do
        subject.features.should eq(Set.new)
      end
    end

    context "with features enabled and disabled" do
      before do
        subject.set_add(features_key, 'stats')
        subject.set_add(features_key, 'cache')
        subject.set_add(features_key, 'search')
      end

      it "returns set of feature names" do
        subject.features.should be_instance_of(Set)
        subject.features.sort.should eq(['cache', 'search', 'stats'])
      end
    end
  end

  describe "#feature_add" do
    context "with string name" do
      before do
        subject.feature_add('search')
      end

      it "adds string to set" do
        subject.set_members(features_key).should include('search')
      end
    end

    context "with symbol name" do
      before do
        subject.feature_add(:search)
      end

      it "adds string to set" do
        subject.set_members(features_key).should include('search')
      end
    end
  end

  describe "instrumentation" do
    let(:instrumenter) { Flipper::Instrumenters::Memory.new }

    subject {
      described_class.new(adapter, :instrumenter => instrumenter)
    }

    it "is recorded for read" do
      subject.read('foo')

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload.should eq({
        :key => 'foo',
        :operation => :read,
        :adapter_name => :memory,
      })
    end

    it "is recorded for write" do
      subject.write('foo', 'bar')

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload.should eq({
        :key => 'foo',
        :value => 'bar',
        :operation => :write,
        :adapter_name => :memory,
      })
    end

    it "is recorded for delete" do
      subject.delete('foo')

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload.should eq({
        :key => 'foo',
        :operation => :delete,
        :adapter_name => :memory,
      })
    end

    it "is recorded for set_members" do
      subject.set_members('foo')

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload.should eq({
        :key => 'foo',
        :operation => :set_members,
        :adapter_name => :memory,
      })
    end

    it "is recorded for set_add" do
      subject.set_add('foo', 'bar')

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload.should eq({
        :key => 'foo',
        :value => 'bar',
        :operation => :set_add,
        :adapter_name => :memory,
      })
    end

    it "is recorded for set_delete" do
      subject.set_delete('foo', 'bar')

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload.should eq({
        :key => 'foo',
        :value => 'bar',
        :operation => :set_delete,
        :adapter_name => :memory,
      })
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      subject.inspect.should eq("#<Flipper::Adapter:#{subject.object_id} name=:memory, use_local_cache=nil>")
    end
  end
end
