require 'helper'
require 'flipper/adapters/memoizable'
require 'flipper/adapters/memory'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Memoizable do
  let(:features_key) { described_class::FeaturesKey }
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:cache)   { {} }

  subject { described_class.new(adapter, cache) }

  it_should_behave_like 'a flipper adapter'

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

      it "memoizes feature" do
        feature = flipper[:stats]
        result = subject.get(feature)
        expect(cache[feature]).to be(result)
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
        expect(result).to eq(adapter_result)
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
        expect(cache[feature]).to be_nil
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
        expect(result).to eq(adapter_result)
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
        expect(cache[feature]).to be_nil
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
        expect(result).to eq(adapter_result)
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
        expect(cache[:flipper_features]).to be(result)
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        expect(subject.features).to eq(adapter.features)
      end
    end
  end

  describe "#add" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes the known features" do
        cache[features_key] = {:some => 'thing'}
        subject.add(flipper[:stats])
        expect(cache).to be_empty
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        expect(subject.add(flipper[:stats])).to eq(adapter.add(flipper[:stats]))
      end
    end
  end

  describe "#remove" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes the known features" do
        cache[features_key] = {:some => 'thing'}
        subject.remove(flipper[:stats])
        expect(cache).to be_empty
      end

      it "unmemoizes the feature" do
        feature = flipper[:stats]
        cache[feature] = {:some => 'thing'}
        subject.remove(feature)
        expect(cache[feature]).to be_nil
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        expect(subject.remove(flipper[:stats])).to eq(adapter.remove(flipper[:stats]))
      end
    end
  end

  describe "#clear" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes feature" do
        feature = flipper[:stats]
        cache[feature] = {:some => 'thing'}
        subject.clear(feature)
        expect(cache[feature]).to be_nil
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        feature = flipper[:stats]
        expect(subject.clear(feature)).to eq(adapter.clear(feature))
      end
    end
  end

  describe "#get_control" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "memoizes control" do
        control = flipper.control(:poll_interval)
        result = subject.get_control(control)
        expect(cache[control]).to be(result)
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        control = flipper.control(:poll_interval)
        result = subject.get_control(control)
        adapter_result = adapter.get_control(control)
        expect(result).to eq(adapter_result)
      end
    end
  end

  describe "#set_control" do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it "unmemoizes control" do
        control = flipper.control(:poll_interval)
        cache[control] = "should be nil"
        subject.set_control(control, "10")
        expect(cache[control]).to be_nil
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it "returns result" do
        control = flipper.control(:poll_interval)
        result = subject.set_control(control, "10")
        adapter_result = adapter.set_control(control, "10")
        expect(result).to eq(adapter_result)
      end
    end
  end
end
