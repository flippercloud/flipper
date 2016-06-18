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

  describe "#mget" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "memoizes value" do
        adapter.set("foo", "foo_value")
        adapter.set("bar", "bar_value")
        result = subject.mget(["foo", "bar"])
        expect(cache["foo"]).to eq("foo_value")
        expect(cache["bar"]).to eq("bar_value")
      end

      it "only mgets keys that are not memoized" do
        cache["foo"] = "foo_value"
        expect(adapter).to receive(:mget).with(["bar"]).and_return({"bar" => "bar_value"})
        result = subject.mget(["foo", "bar"])
        expect(cache["foo"]).to eq("foo_value")
        expect(cache["bar"]).to eq("bar_value")
      end

      it "doesn't mget if all memoized" do
        cache["foo"] = "foo_value"
        cache["bar"] = "bar_value"
        expect(adapter).to_not receive(:mget)
        result = subject.mget(["foo", "bar"])
        expect(cache["foo"]).to eq("foo_value")
        expect(cache["bar"]).to eq("bar_value")
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        adapter.set("foo", "bar")
        result = subject.mget(["foo"])
        adapter_result = adapter.mget(["foo"])
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

  describe "#mset" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes keys" do
        cache["foo"] = "old"
        cache["bar"] = "old"
        subject.mset("foo" => "new", "bar" => "old")
        expect(cache["foo"]).to be_nil
        expect(cache["bar"]).to be_nil
      end

      it "calls mset on adapter" do
        expect(adapter).to receive(:mset).with({"foo" => "value"}).and_return(true)
        subject.mset({"foo" => "value"})
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        result = subject.mset("foo" => "new")
        adapter_result = adapter.mset("foo" => "new")
        expect(result).to eq(adapter_result)
      end

      it "calls mset on adapter" do
        expect(adapter).to receive(:mset).with({"foo" => "value"}).and_return(true)
        subject.mset({"foo" => "value"})
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
        adapter_result = adapter.set("foo", "new")
        expect(result).to eq(adapter_result)
      end
    end
  end

  describe "#mdel" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes keys" do
        cache["foo"] = "old"
        cache["bar"] = "old"
        subject.mdel(["foo", "bar"])
        expect(cache["foo"]).to be_nil
        expect(cache["bar"]).to be_nil
      end

      it "calls mdel on adapter" do
        expect(adapter).to receive(:mdel).with({"foo" => "value"}).and_return(true)
        subject.mdel({"foo" => "value"})
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        result = subject.mdel(["foo"])
        adapter_result = adapter.mdel(["foo"])
        expect(result).to eq(adapter_result)
      end

      it "calls mdel on adapter" do
        expect(adapter).to receive(:mdel).with(["foo"]).and_return(true)
        subject.mdel(["foo"])
      end
    end
  end
end
