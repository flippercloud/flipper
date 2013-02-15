require 'helper'
require 'flipper/adapters/memoizable'
require 'flipper/adapters/memory'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Memoizable do
  let(:features_key) { described_class::FeaturesKey }

  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:cache) { Thread.current[:flipper_memoize_cache] }

  after do
    described_class.memoize = nil
  end

  subject { described_class.new(adapter) }

  it_should_behave_like 'a flipper adapter'

  describe "#memoize=" do
    it "sets value" do
      subject.memoize = true
      subject.memoizing?.should be_true

      subject.memoize = false
      subject.memoizing?.should be_false
    end

    it "clears the local cache" do
      subject.cache['some'] = 'thing'
      subject.memoize = true
      subject.cache.should be_empty
    end
  end

  describe "#memoizing?" do
    it "returns true if enabled" do
      subject.memoize = true
      subject.memoizing?.should be_true
    end

    it "returns false if disabled" do
      subject.memoize = false
      subject.memoizing?.should be_false
    end
  end

  describe "#get" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "memoizes feature" do
        feature = flipper[:stats]
        result = subject.get(feature)
        cache[feature].should be(result)
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        feature = flipper[:stats]
        result = subject.get(feature)
        adapter_result = adapter.get(feature)
        result.should eq(adapter_result)
      end
    end
  end

  describe "#enable" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes feature" do
        feature = flipper[:stats]
        gate = feature.gate(:boolean)
        cache[feature] = {:some => 'thing'}
        subject.enable(feature, gate, flipper.bool)
        cache[feature].should be_nil
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        feature = flipper[:stats]
        gate = feature.gate(:boolean)
        result = subject.enable(feature, gate, flipper.bool)
        adapter_result = adapter.enable(feature, gate, flipper.bool)
        result.should eq(adapter_result)
      end
    end
  end

  describe "#disable" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes feature" do
        feature = flipper[:stats]
        gate = feature.gate(:boolean)
        cache[feature] = {:some => 'thing'}
        subject.disable(feature, gate, flipper.bool)
        cache[feature].should be_nil
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        feature = flipper[:stats]
        gate = feature.gate(:boolean)
        result = subject.disable(feature, gate, flipper.bool)
        adapter_result = adapter.disable(feature, gate, flipper.bool)
        result.should eq(adapter_result)
      end
    end
  end

  describe "#features" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "memoizes features" do
        flipper[:stats].enable
        flipper[:search].disable
        result = subject.features
        cache[:flipper_features].should be(result)
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        subject.features.should eq(adapter.features)
      end
    end
  end

  describe "#add" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes features" do
        cache[features_key] = {:some => 'thing'}
        subject.add(flipper[:stats])
        cache.should be_empty
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        subject.add(flipper[:stats]).should eq(adapter.add(flipper[:stats]))
      end
    end
  end
end
