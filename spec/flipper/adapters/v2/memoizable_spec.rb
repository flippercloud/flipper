require 'helper'
require 'flipper/adapters/v2/memoizable'
require 'flipper/adapters/v2/memory'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::Memoizable do
  let(:features_key) { described_class::FeaturesKey }
  let(:adapter) { Flipper::Adapters::V2::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:cache)   { {} }

  subject { described_class.new(adapter, cache) }

  it_should_behave_like 'a v2 flipper adapter'

  it "forwards missing methods to underlying adapter" do
    adapter = Class.new do
      def foo
        :foo
      end
    end.new
    memoizable = described_class.new(adapter)
    expect(memoizable.foo).to eq(:foo)
  end

  describe "#name" do
    it "is instrumented" do
      expect(subject.name).to be(:memoizable)
    end
  end

  describe "#memoize=" do
    it "sets value" do
      subject.memoize = true
      expect(subject.memoizing?).to eq(true)

      subject.memoize = false
      expect(subject.memoizing?).to eq(false)
    end

    it "clears the local cache" do
      subject.cache['some'] = 'thing'
      subject.memoize = true
      expect(subject.cache).to be_empty
    end
  end

  describe "#memoizing?" do
    it "returns true if enabled" do
      subject.memoize = true
      expect(subject.memoizing?).to eq(true)
    end

    it "returns false if disabled" do
      subject.memoize = false
      expect(subject.memoizing?).to eq(false)
    end
  end

  describe "#get" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "memoizes value" do
        adapter.set("foo", "bar")
        result = subject.get("foo")
        expect(cache["foo"]).to be(result)
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        adapter.set("foo", "bar")
        result = subject.get("foo")
        adapter_result = adapter.get("foo")
        expect(result).to eq(adapter_result)
      end
    end
  end

  describe "#set" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes feature" do
        cache["foo"] = "old"
        subject.set("foo", "new")
        expect(cache["foo"]).to be_nil
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        result = subject.set("foo", "new")
        adapter_result = adapter.set("foo", "new")
        expect(result).to eq(adapter_result)
      end
    end
  end

  describe "#del" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes feature" do
        cache["foo"] = "old"
        subject.del("foo")
        expect(cache["foo"]).to be_nil
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        result = subject.del("foo")
        adapter_result = adapter.del("foo")
        expect(result).to eq(adapter_result)
      end
    end
  end
end
