require 'helper'
require 'flipper/dsl'
require 'flipper/adapters/memory'

RSpec.describe Flipper::DSL do
  subject { described_class.new(adapter) }

  let(:adapter) { Flipper::Adapters::Memory.new }

  describe '#initialize' do
    it 'sets adapter' do
      dsl = described_class.new(adapter)
      expect(dsl.adapter).not_to be_nil
    end

    it 'defaults instrumenter to noop' do
      dsl = described_class.new(adapter)
      expect(dsl.instrumenter).to be(Flipper::Instrumenters::Noop)
    end

    context 'with overriden instrumenter' do
      let(:instrumenter) { double('Instrumentor', instrument: nil) }

      it 'overrides default instrumenter' do
        dsl = described_class.new(adapter, instrumenter: instrumenter)
        expect(dsl.instrumenter).to be(instrumenter)
      end
    end
  end

  describe '#feature' do
    it_should_behave_like 'a DSL feature' do
      let(:method_name) { :feature }
      let(:instrumenter) { double('Instrumentor', instrument: nil) }
      let(:feature) { dsl.send(method_name, :stats) }
      let(:dsl) { described_class.new(adapter, instrumenter: instrumenter) }
    end
  end

  describe '#preload' do
    let(:instrumenter) { double('Instrumentor', instrument: nil) }
    let(:dsl) { described_class.new(adapter, instrumenter: instrumenter) }
    let(:names) { %i(stats shiny) }
    let(:features) { dsl.preload(names) }

    it 'returns array of features' do
      expect(features).to all be_instance_of(Flipper::Feature)
    end

    it 'sets names' do
      expect(features.map(&:name)).to eq(names)
    end

    it 'sets adapter' do
      features.each do |feature|
        expect(feature.adapter.name).to eq(dsl.adapter.name)
      end
    end

    it 'sets instrumenter' do
      features.each do |feature|
        expect(feature.instrumenter).to eq(dsl.instrumenter)
      end
    end

    it 'memoizes the feature' do
      features.each do |feature|
        expect(dsl.feature(feature.name)).to equal(feature)
      end
    end
  end

  describe '#[]' do
    it_should_behave_like 'a DSL feature' do
      let(:method_name) { :[] }
      let(:instrumenter) { double('Instrumentor', instrument: nil) }
      let(:feature) { dsl.send(method_name, :stats) }
      let(:dsl) { described_class.new(adapter, instrumenter: instrumenter) }
    end
  end

  describe '#boolean' do
    it_should_behave_like 'a DSL boolean method' do
      let(:method_name) { :boolean }
    end
  end

  describe '#bool' do
    it_should_behave_like 'a DSL boolean method' do
      let(:method_name) { :bool }
    end
  end

  describe '#group' do
    context 'for registered group' do
      before do
        @group = Flipper.register(:admins) {}
      end

      it 'returns group' do
        expect(subject.group(:admins)).to eq(@group)
      end

      it 'always returns same instance for same name' do
        expect(subject.group(:admins)).to equal(subject.group(:admins))
      end
    end

    context 'for unregistered group' do
      it 'raises error' do
        expect do
          subject.group(:admins)
        end.to raise_error(Flipper::GroupNotRegistered)
      end
    end
  end

  describe '#actor' do
    context 'for a thing' do
      it 'returns actor instance' do
        thing = Struct.new(:flipper_id).new(33)
        actor = subject.actor(thing)
        expect(actor).to be_instance_of(Flipper::Types::Actor)
        expect(actor.value).to eq('33')
      end
    end

    context 'for nil' do
      it 'raises argument error' do
        expect do
          subject.actor(nil)
        end.to raise_error(ArgumentError)
      end
    end

    context 'for something that is not actor wrappable' do
      it 'raises argument error' do
        expect do
          subject.actor(Object.new)
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe '#time' do
    before do
      @result = subject.time(5)
    end

    it 'returns percentage of time' do
      expect(@result).to be_instance_of(Flipper::Types::PercentageOfTime)
    end

    it 'sets value' do
      expect(@result.value).to eq(5)
    end

    it 'is aliased to percentage_of_time' do
      expect(@result).to eq(subject.percentage_of_time(@result.value))
    end
  end

  describe '#actors' do
    before do
      @result = subject.actors(17)
    end

    it 'returns percentage of actors' do
      expect(@result).to be_instance_of(Flipper::Types::PercentageOfActors)
    end

    it 'sets value' do
      expect(@result.value).to eq(17)
    end

    it 'is aliased to percentage_of_actors' do
      expect(@result).to eq(subject.percentage_of_actors(@result.value))
    end
  end

  describe '#features' do
    context 'with no features enabled/disabled' do
      it 'defaults to empty set' do
        expect(subject.features).to eq(Set.new)
      end
    end

    context 'with features enabled and disabled' do
      before do
        subject[:stats].enable
        subject[:cache].enable
        subject[:search].disable
      end

      it 'returns set of feature instances' do
        expect(subject.features).to be_instance_of(Set)
        subject.features.each do |feature|
          expect(feature).to be_instance_of(Flipper::Feature)
        end
        expect(subject.features.map(&:name).map(&:to_s).sort).to eq(%w(cache search stats))
      end
    end
  end

  describe '#enable/disable' do
    it 'enables and disables the feature' do
      expect(subject[:stats].boolean_value).to eq(false)
      subject.enable(:stats)
      expect(subject[:stats].boolean_value).to eq(true)

      subject.disable(:stats)
      expect(subject[:stats].boolean_value).to eq(false)
    end
  end

  describe '#enable_actor/disable_actor' do
    it 'enables and disables the feature for actor' do
      actor = Struct.new(:flipper_id).new(5)

      expect(subject[:stats].actors_value).to be_empty
      subject.enable_actor(:stats, actor)
      expect(subject[:stats].actors_value).to eq(Set['5'])

      subject.disable_actor(:stats, actor)
      expect(subject[:stats].actors_value).to be_empty
    end
  end

  describe '#enable_group/disable_group' do
    it 'enables and disables the feature for group' do
      actor = Struct.new(:flipper_id).new(5)
      group = Flipper.register(:fives) { |actor| actor.flipper_id == 5 }

      expect(subject[:stats].groups_value).to be_empty
      subject.enable_group(:stats, :fives)
      expect(subject[:stats].groups_value).to eq(Set['fives'])

      subject.disable_group(:stats, :fives)
      expect(subject[:stats].groups_value).to be_empty
    end
  end

  describe '#enable_percentage_of_time/disable_percentage_of_time' do
    it 'enables and disables the feature for percentage of time' do
      expect(subject[:stats].percentage_of_time_value).to be(0)
      subject.enable_percentage_of_time(:stats, 6)
      expect(subject[:stats].percentage_of_time_value).to be(6)

      subject.disable_percentage_of_time(:stats)
      expect(subject[:stats].percentage_of_time_value).to be(0)
    end
  end

  describe '#enable_percentage_of_actors/disable_percentage_of_actors' do
    it 'enables and disables the feature for percentage of time' do
      expect(subject[:stats].percentage_of_actors_value).to be(0)
      subject.enable_percentage_of_actors(:stats, 6)
      expect(subject[:stats].percentage_of_actors_value).to be(6)

      subject.disable_percentage_of_actors(:stats)
      expect(subject[:stats].percentage_of_actors_value).to be(0)
    end
  end

  describe '#remove' do
    it 'removes the feature' do
      subject.enable(:stats)

      expect { subject.remove(:stats) }.to change { subject.enabled?(:stats) }.to(false)

      expect(subject.features).to be_empty
    end
  end
end
