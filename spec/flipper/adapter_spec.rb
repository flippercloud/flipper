require 'helper'
require 'flipper/adapter'
require 'flipper/adapters/memory'
require 'flipper/instrumenters/memory'

describe Flipper::Adapter do
  let(:local_cache)  { {} }
  let(:source)       { {} }
  let(:adapter)      { Flipper::Adapters::Memory.new(source) }
  let(:flipper)      { Flipper.new(adapter) }

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

    describe "#get" do
      before do
        @group = Flipper.register(:admins) { |thing| thing.admin? }
        @actor = Struct.new(:flipper_id).new('13')
        @actors = flipper.actors(20)
        @random = flipper.random(10)
        @feature = flipper[:stats]

        @feature.enable @group
        @feature.enable @actors
        @feature.enable @random
        @feature.enable @actor

        @result = subject.get(@feature)
      end

      it "returns hash of gate => value" do
        @result.should be_instance_of(Hash)
        @result[@feature.gate(:boolean)].should be_false
        @result[@feature.gate(:actor)].should eq(Set['13'])
        @result[@feature.gate(:group)].should eq(Set['admins'])
        @result[@feature.gate(:percentage_of_actors)].should eq('20')
        @result[@feature.gate(:percentage_of_random)].should eq('10')
      end

      it "memoizes adapter get value" do
        local_cache[@feature.name].should eq(@result)
        adapter.should_not_receive(:get)
        subject.get(@feature).should be(@result)
      end
    end
  end

  context "with local cache disabled" do
    before do
      subject.use_local_cache = false
    end

    describe "#get" do
      before do
        @group = Flipper.register(:admins) { |thing| thing.admin? }
        @actor = Struct.new(:flipper_id).new('13')
        @actors = flipper.actors(20)
        @random = flipper.random(10)
        @feature = flipper[:stats]

        @feature.enable @group
        @feature.enable @actors
        @feature.enable @random
        @feature.enable @actor

        @result = subject.get(@feature)
      end

      it "returns hash of gate => value" do
        @result.should be_instance_of(Hash)
        @result[@feature.gate(:boolean)].should be_false
        @result[@feature.gate(:actor)].should eq(Set['13'])
        @result[@feature.gate(:group)].should eq(Set['admins'])
        @result[@feature.gate(:percentage_of_actors)].should eq('20')
        @result[@feature.gate(:percentage_of_random)].should eq('10')
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

  describe "instrumentation" do
    let(:instrumenter) { Flipper::Instrumenters::Memory.new }
    let(:feature) { flipper[:stats] }
    let(:gate) { feature.gate(:percentage_of_actors) }
    let(:thing) { flipper.actors(22) }

    subject {
      described_class.new(adapter, :instrumenter => instrumenter)
    }

    it "is recorded for get" do
      result = subject.get(feature)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:get)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:feature_name].should eq(:stats)
      event.payload[:result].should be(result)
    end

    it "is recorded for enable" do
      result = subject.enable(feature, gate, thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:enable)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:feature_name].should eq(:stats)
      event.payload[:gate_name].should eq(:percentage_of_actors)
      event.payload[:result].should be(result)
    end

    it "is recorded for disable" do
      result = subject.disable(feature, gate, thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:disable)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:feature_name].should eq(:stats)
      event.payload[:gate_name].should eq(:percentage_of_actors)
      event.payload[:result].should be(result)
    end

    it "is recorded for add" do
      result = subject.add(feature)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:add)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:feature_name].should eq(:stats)
      event.payload[:result].should be(result)
    end

    it "is recorded for features" do
      result = subject.features

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:features)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:result].should be(result)
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      subject.inspect.should eq("#<Flipper::Adapter:#{subject.object_id} name=:memory, use_local_cache=nil>")
    end
  end
end
