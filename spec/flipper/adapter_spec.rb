require 'helper'
require 'flipper/adapter'
require 'flipper/adapters/memory'

describe Flipper::Adapter do
  let(:local_cache) { {} }
  let(:adapter)     { Flipper::Adapters::Memory.new }

  subject { described_class.new(adapter, local_cache) }

  describe ".wrap" do
    context "with Flipper::Adapter instance" do
      before do
        @result = described_class.wrap(subject)
      end

      it "returns self" do
        @result.should be(subject)
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
        @result.adapter.should eq(adapter)
      end
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
        adapter.write 'foo', Set[1, 2]
        @result = subject.set_members('foo')
      end

      it "returns result of adapter set members" do
        @result.should eq(Set[1, 2])
      end

      it "memoizes key" do
        local_cache['foo'].should eq(Set[1, 2])
        adapter.should_not_receive(:set_members)
        subject.set_members('foo').should eq(Set[1, 2])
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
        adapter.write 'foo', Set[1]
        local_cache['foo'] = Set[1]
        subject.set_add 'foo', 2
      end

      it "returns result of adapter set members" do
        adapter.set_members('foo').should eq(Set[1, 2])
      end

      it "unmemoizes key" do
        local_cache.key?('foo').should be_false
      end
    end

    describe "#set_delete" do
      before do
        adapter.write 'foo', Set[1, 2, 3]
        local_cache['foo'] = Set[1, 2, 3]
        subject.set_delete 'foo', 3
      end

      it "returns result of adapter set members" do
        adapter.set_members('foo').should eq(Set[1, 2])
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
        adapter.write 'foo', Set[1, 2]
        @result = subject.set_members('foo')
      end

      it "returns result of adapter set members" do
        @result.should eq(Set[1, 2])
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
        adapter.write 'foo', Set[1]
        local_cache['foo'] = Set[1]
        subject.set_add 'foo', 2
      end

      it "performs adapter set add" do
        adapter.set_members('foo').should eq(Set[1, 2])
      end

      it "does not attempt to delete local cache key" do
        local_cache.key?('foo').should be_true
      end
    end

    describe "#set_delete" do
      before do
        adapter.write 'foo', Set[1, 2, 3]
        local_cache['foo'] = Set[1, 2, 3]
        subject.set_delete 'foo', 3
      end

      it "performs adapter set delete" do
        adapter.set_members('foo').should eq(Set[1, 2])
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
end
