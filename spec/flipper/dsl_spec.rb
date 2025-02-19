require 'flipper/dsl'

RSpec.describe Flipper::DSL do
  subject { described_class.new(adapter) }

  let(:adapter) { Flipper::Adapters::Memory.new }

  describe '#initialize' do
    context 'when using default memoize strategy' do
      it 'wraps the given adapter with Flipper::Adapters::Memoizable' do
        dsl = described_class.new(adapter)
        expect(dsl.adapter.class).to be(Flipper::Adapters::Memoizable)
        expect(dsl.adapter.adapter).to be(adapter)
      end
    end

    context 'when disabling memoization' do
      it 'uses the given adapter directly' do
        dsl = described_class.new(adapter, memoize: false)
        expect(dsl.adapter).to be(adapter)
      end
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

  describe '#preload_all' do
    let(:instrumenter) { double('Instrumentor', instrument: nil) }
    let(:dsl) do
      names.each { |name| adapter.add subject[name] }
      described_class.new(adapter, instrumenter: instrumenter)
    end
    let(:names) { %i(stats shiny) }
    let(:features) { dsl.preload_all }

    it 'returns array of features' do
      expect(features).to all be_instance_of(Flipper::Feature)
    end

    it 'sets names' do
      expect(features.map(&:key)).to eq(names.map(&:to_s))
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

  describe '#group' do
    context 'for registered group' do
      before do
        @group = Flipper.register(:admins) {}
      end

      it 'delegates to Flipper' do
        expect(Flipper).to receive(:group).with(:admins).and_return(@group)
        expect(subject.group(:admins)).to be(@group)
      end
    end
  end

  describe '#expression' do
    it "returns nil if feature has no expression" do
      expect(subject.expression(:stats)).to be(nil)
    end

    it "returns expression if feature has expression" do
      expression = Flipper.property(:plan).eq("basic")
      subject[:stats].enable_expression expression
      expect(subject.expression(:stats)).to eq(expression)
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

  describe '#enable_expression/disable_expression' do
    it 'enables and disables the feature for the expression' do
      expression = Flipper.property(:plan).eq("basic")

      expect(subject[:stats].expression).to be(nil)
      subject.enable_expression(:stats, expression)
      expect(subject[:stats].expression).to eq(expression)

      subject.disable_expression(:stats)
      expect(subject[:stats].expression).to be(nil)
    end
  end

  describe '#add_expression/remove_expression' do
    it 'enables and disables the feature for the expression' do
      expression = Flipper.property(:plan).eq("basic")
      any_expression = Flipper.any(expression)

      expect(subject[:stats].expression).to be(nil)
      subject.add_expression(:stats, any_expression)
      expect(subject[:stats].expression).to eq(any_expression)

      subject.remove_expression(:stats, expression)
      expect(subject[:stats].expression).to eq(Flipper.any)
    end
  end

  describe '#enable_actor/disable_actor' do
    it 'enables and disables the feature for actor' do
      actor = Flipper::Actor.new(5)

      expect(subject[:stats].actors_value).to be_empty
      subject.enable_actor(:stats, actor)
      expect(subject[:stats].actors_value).to eq(Set['5'])

      subject.disable_actor(:stats, actor)
      expect(subject[:stats].actors_value).to be_empty
    end
  end

  describe '#enable_group/disable_group' do
    it 'enables and disables the feature for group' do
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

    it 'can enable/disable float values' do
      expect(subject[:stats].percentage_of_time_value).to be(0)
      subject.enable_percentage_of_time(:stats, 0.01)
      expect(subject[:stats].percentage_of_time_value).to be(0.01)

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

    it 'can enable/disable float values' do
      expect(subject[:stats].percentage_of_actors_value).to be(0)
      subject.enable_percentage_of_actors(:stats, 0.01)
      expect(subject[:stats].percentage_of_actors_value).to be(0.01)

      subject.disable_percentage_of_actors(:stats)
      expect(subject[:stats].percentage_of_actors_value).to be(0)
    end
  end

  describe '#add' do
    it 'adds the feature' do
      expect(subject.features).to eq(Set.new)
      subject.add(:stats)
      expect(subject.features).to eq(Set[subject[:stats]])
    end
  end

  describe '#exist?' do
    it 'returns true if the feature is added in adapter' do
      subject.add(:stats)
      expect(subject.exist?(:stats)).to be(true)
    end

    it 'returns false if the feature is NOT added in adapter' do
      expect(subject.exist?(:stats)).to be(false)
    end
  end

  describe '#remove' do
    it 'removes the feature' do
      subject.adapter.add(subject[:stats])
      expect(subject.features).to eq(Set[subject[:stats]])
      subject.remove(:stats)
      expect(subject.features).to eq(Set.new)
    end
  end

  describe '#import' do
    context "with flipper instance" do
      it 'delegates to adapter' do
        destination_flipper = build_flipper
        expect(subject.adapter).to receive(:import).with(destination_flipper)
        subject.import(destination_flipper)
      end
    end

    context "with flipper adapter" do
      it 'delegates to adapter' do
        destination_flipper = build_flipper
        expect(subject.adapter).to receive(:import).with(destination_flipper.adapter)
        subject.import(destination_flipper.adapter)
      end
    end
  end

  describe "#export" do
    it 'delegates to adapter' do
      expect(subject.export).to eq(subject.adapter.export)
      expect(subject.export(format: :json)).to eq(subject.adapter.export(format: :json))
    end
  end

  describe '#memoize=' do
    it 'delegates to adapter' do
      expect(subject.adapter).not_to be_memoizing
      subject.memoize = true
      expect(subject.adapter).to be_memoizing
    end
  end

  describe '#memoizing?' do
    it 'delegates to adapter' do
      subject.memoize = false
      expect(subject.adapter.memoizing?).to eq(subject.memoizing?)
      subject.memoize = true
      expect(subject.adapter.memoizing?).to eq(subject.memoizing?)
    end
  end
end
