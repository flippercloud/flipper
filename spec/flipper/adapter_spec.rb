require 'helper'
require 'flipper/adapter'
require 'flipper/adapters/memory'

describe Flipper::Adapter do
  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  subject {
    described_class.new(adapter)
  }

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

  context "#use_local_cache=" do
    before do
      subject.local_cache['foo'] = 'bar'
      subject.use_local_cache = true
    end

    it "sets value" do
      subject.use_local_cache.should be_true
    end

    it "clears the local cache" do
      subject.local_cache.should be_empty
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
        adapter.should_not_receive(:read)
        subject.read('foo').should eq('bar')
      end
    end

    describe "#write" do
      before do
        adapter.write 'foo', 'bar'
        subject.write 'foo', 'swanky'
      end

      it "performs adapter write" do
        adapter.read('foo').should eq('swanky')
      end

      it "unmemoizes key" do
        subject.local_cache.key?('foo').should be_false
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
        subject.local_cache.key?('foo').should be_false
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
        adapter.should_not_receive(:set_members)
        subject.set_members('foo').should eq(Set[1, 2])
      end
    end

    describe "#set_add" do
      before do
        adapter.write 'foo', Set[1]
        subject.set_members('foo') # force local cache
        subject.set_add 'foo', 2
      end

      it "returns result of adapter set members" do
        adapter.read('foo').should eq(Set[1, 2])
      end

      it "unmemoizes key" do
        subject.local_cache.key?('foo').should be_false
      end
    end

    describe "#set_delete" do
      before do
        adapter.write 'foo', Set[1, 2, 3]
        subject.set_members('foo') # force local cache
        subject.set_delete 'foo', 3
      end

      it "returns result of adapter set members" do
        adapter.read('foo').should eq(Set[1, 2])
      end

      it "unmemoizes key" do
        subject.local_cache.key?('foo').should be_false
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
        subject.should_receive(:read)
        subject.read('foo')
      end
    end

    describe "#write" do
      before do
        adapter.write 'foo', 'bar'
        subject.write 'foo', 'swanky'
      end

      it "performs adapter write" do
        adapter.read('foo').should eq('swanky')
      end

      it "does not attempt to delete local cache key" do
        subject.local_cache.should_not_receive(:delete)
        subject.write 'foo', 'swanky'
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

      it "does not attempt to delete local cache key" do
        subject.local_cache.should_not_receive(:delete)
        subject.delete 'foo'
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
        subject.should_receive(:set_members)
        subject.set_members('foo')
      end
    end

    describe "#set_add" do
      before do
        adapter.write 'foo', Set[1]
        subject.set_members('foo') # force local cache
        subject.set_add 'foo', 2
      end

      it "performs adapter set add" do
        adapter.read('foo').should eq(Set[1, 2])
      end

      it "does not attempt to delete local cache key" do
        subject.local_cache.should_not_receive(:delete)
        subject.set_add('foo', 3)
      end
    end

    describe "#set_delete" do
      before do
        adapter.write 'foo', Set[1, 2, 3]
        subject.set_members('foo') # force local cache
        subject.set_delete 'foo', 3
      end

      it "performs adapter set delete" do
        adapter.read('foo').should eq(Set[1, 2])
      end

      it "does not attempt to delete local cache key" do
        subject.local_cache.should_not_receive(:delete)
        subject.set_delete 'foo', 3
      end
    end
  end
end
