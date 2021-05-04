require 'flipper/adapters/memoizable'
require 'flipper/adapters/operation_logger'

RSpec.describe Flipper::Adapters::Memoizable do
  let(:features_key) { described_class::FeaturesKey }
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:cache)   { {} }

  subject { described_class.new(adapter, cache) }

  it_should_behave_like 'a flipper adapter'

  it 'forwards missing methods to underlying adapter' do
    adapter = Class.new do
      def foo
        :foo
      end
    end.new
    memoizable = described_class.new(adapter)
    expect(memoizable.foo).to eq(:foo)
  end

  describe '#name' do
    it 'is instrumented' do
      expect(subject.name).to be(:memoizable)
    end
  end

  describe '#get' do
    it 'memoizes feature' do
      feature = flipper[:stats]
      result = subject.get(feature)
      expect(cache[described_class.key_for(feature.key)]).to be(result)
    end
  end

  describe '#get_multi' do
    it 'memoizes features' do
      names = %i(stats shiny)
      features = names.map { |name| flipper[name] }
      results = subject.get_multi(features)
      features.each do |feature|
        expect(cache[described_class.key_for(feature.key)]).not_to be(nil)
        expect(cache[described_class.key_for(feature.key)]).to be(results[feature.key])
      end
    end
  end

  describe '#get_all' do
    it 'memoizes features' do
      names = %i(stats shiny)
      features = names.map { |name| flipper[name].tap(&:enable) }
      results = subject.get_all
      features.each do |feature|
        expect(cache[described_class.key_for(feature.key)]).not_to be(nil)
        expect(cache[described_class.key_for(feature.key)]).to be(results[feature.key])
      end
      expect(cache[subject.class::FeaturesKey]).to eq(names.map(&:to_s).to_set)
    end

    it 'only calls get_all once for memoized adapter' do
      adapter = Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
      cache = {}
      instance = described_class.new(adapter, cache)

      instance.get_all
      expect(adapter.count(:get_all)).to be(1)

      instance.get_all
      expect(adapter.count(:get_all)).to be(1)
    end

    it 'returns default_config for unknown feature keys' do
      first = subject.get_all
      expect(first['doesntexist']).to eq(subject.default_config)

      second = subject.get_all
      expect(second['doesntexist']).to eq(subject.default_config)
    end
  end

  describe '#enable' do
    it 'unmemoizes feature' do
      feature = flipper[:stats]
      gate = feature.gate(:boolean)
      cache[described_class.key_for(feature.key)] = { some: 'thing' }
      subject.enable(feature, gate, flipper.bool)
      expect(cache[described_class.key_for(feature.key)]).to be_nil
    end
  end

  describe '#disable' do
    it 'unmemoizes feature' do
      feature = flipper[:stats]
      gate = feature.gate(:boolean)
      cache[described_class.key_for(feature.key)] = { some: 'thing' }
      subject.disable(feature, gate, flipper.bool)
      expect(cache[described_class.key_for(feature.key)]).to be_nil
    end
  end

  describe '#features' do
    it 'memoizes features' do
      flipper[:stats].enable
      flipper[:search].disable
      result = subject.features
      expect(cache[:flipper_features]).to be(result)
    end
  end

  describe '#add' do
    it 'unmemoizes the known features' do
      cache[features_key] = { some: 'thing' }
      subject.add(flipper[:stats])
      expect(cache).to be_empty
    end
  end

  describe '#remove' do
    it 'unmemoizes the known features' do
      cache[features_key] = { some: 'thing' }
      subject.remove(flipper[:stats])
      expect(cache).to be_empty
    end

    it 'unmemoizes the feature' do
      feature = flipper[:stats]
      cache[described_class.key_for(feature.key)] = { some: 'thing' }
      subject.remove(feature)
      expect(cache[described_class.key_for(feature.key)]).to be_nil
    end
  end

  describe '#clear' do
    it 'unmemoizes feature' do
      feature = flipper[:stats]
      cache[described_class.key_for(feature.key)] = { some: 'thing' }
      subject.clear(feature)
      expect(cache[described_class.key_for(feature.key)]).to be_nil
    end
  end
end
