require 'flipper/adapters/fallback_to_cached'

RSpec.describe Flipper::Adapters::FallbackToCached do
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(subject, memoize: false) }
  let(:feature_a) { flipper[:malware_rule] }
  let(:feature_b) { flipper[:spam_rule] }

  subject { described_class.new(adapter) }

  before do
    feature_a.enable
    feature_b.disable
  end

  describe "#features" do
    it "uses primary adapter by default and caches value" do
      expect(adapter).to receive(:features).and_call_original
      expect(subject.features).to_not be_empty
    end

    it "falls back to cached value if primary adapter raises an error" do
      subject.features
      expect(adapter).to receive(:features).and_raise(StandardError)
      expect(subject.features).to_not be_empty
    end

    it "raises an error if primary adapter fails and cache is empty" do
      expect(adapter).to receive(:features).and_raise(StandardError)
      expect { subject.features }.to raise_error StandardError
    end
  end

  describe "#get" do
    it "uses primary adapter by default and caches value" do
      expect(adapter).to receive(:get).with(feature_a).and_call_original
      expect(subject.get(feature_a)).to_not be_nil
    end

    it "falls back to cached value if primary adapter raises an error" do
      subject.get(feature_a)
      expect(adapter).to receive(:get).with(feature_a).and_raise(StandardError)
      expect(subject.get(feature_a)).to_not be_nil
    end

    it "raises an error if primary adapter fails and cache is empty" do
      expect(adapter).to receive(:get).with(feature_a).and_raise(StandardError)
      expect { subject.get(feature_a) }.to raise_error StandardError
    end
  end

  describe "#get_multi" do
    it "uses primary adapter by default and caches value" do
      expect(adapter).to receive(:get_multi).with([feature_a, feature_b]).and_call_original
      expect(subject.get_multi([feature_a, feature_b])).to_not be_empty
    end

    it "falls back to cached value if primary adapter raises an error" do
      subject.get_multi([feature_a, feature_b])
      expect(adapter).to receive(:get_multi).with([feature_a, feature_b]).and_raise(StandardError)
      expect(subject.get_multi([feature_a, feature_b])).to_not be_empty
    end

    it "raises an error if primary adapter fails and cache is empty" do
      expect(adapter).to receive(:get_multi).with([feature_a, feature_b]).and_raise(StandardError)
      expect { subject.get_multi([feature_a, feature_b]) }.to raise_error StandardError
    end
  end

  describe "#get_all" do
    it "uses primary adapter by default and caches value" do
      expect(adapter).to receive(:get_all).and_call_original
      expect(subject.get_all).to_not be_empty
    end

    it "falls back to cached value if primary adapter raises an error" do
      subject.get_all
      expect(adapter).to receive(:get_all).and_raise(StandardError)
      expect(subject.get_all).to_not be_empty
    end

    it "raises an error if primary adapter fails and cache is empty" do
      subject.cache.clear
      expect(adapter).to receive(:get_all).and_raise(StandardError)
      expect { subject.get_all }.to raise_error StandardError
    end
  end
end
