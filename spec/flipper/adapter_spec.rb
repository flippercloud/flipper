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

  describe "#initialize" do
    it "wraps adapter with instrumentation" do
      instance = described_class.new(adapter)
      instance.adapter.should be_instance_of(Flipper::Adapters::Instrumented)
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
      instance.adapter.instrumenter.should be(instrumenter)
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
end
