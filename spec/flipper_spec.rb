require 'helper'

RSpec.describe Flipper do
  describe '.new' do
    it 'returns new instance of dsl' do
      instance = described_class.new(double('Adapter'))
      expect(instance).to be_instance_of(Flipper::DSL)
    end
  end

  describe '.configure' do
    it 'yield configuration instance' do
      Flipper.configure do |config|
        expect(config).to be_instance_of(Flipper::Configuration)
      end
    end
  end

  describe '.configuration' do
    it 'returns configuration instance' do
      expect(Flipper.configuration).to be_instance_of(Flipper::Configuration)
    end
  end

  describe '.configuration=' do
    it "sets configuration instance" do
      configuration = Flipper::Configuration.new
      Flipper.configuration = configuration
      expect(Flipper.configuration).to be(configuration)
    end
  end

  describe '.instance' do
    it 'returns DSL instance using result of default invocation' do
      instance = Flipper.new(Flipper::Adapters::Memory.new)
      Flipper.configure do |config|
        config.default { instance }
      end
      expect(Flipper.instance).to be(instance)
      expect(Flipper.instance).to be(Flipper.instance) # memoized
    end
  end

  describe "delegation to instance" do
    let(:group) { Flipper::Types::Group.new(:admins) }
    let(:actor) { Flipper::Actor.new("1") }

    before do
      Flipper.configure do |config|
        config.default { Flipper.new(Flipper::Adapters::Memory.new) }
      end
    end

    it 'delegates enabled? to instance' do
      expect(Flipper.enabled?(:search)).to eq(Flipper.instance.enabled?(:search))
      Flipper.instance.enable(:search)
      expect(Flipper.enabled?(:search)).to eq(Flipper.instance.enabled?(:search))
    end

    it 'delegates enable to instance' do
      Flipper.enable(:search)
      expect(Flipper.instance.enabled?(:search)).to be(true)
    end

    it 'delegates disable to instance' do
      Flipper.disable(:search)
      expect(Flipper.instance.enabled?(:search)).to be(false)
    end

    it 'delegates bool to instance' do
      expect(Flipper.bool).to eq(Flipper.instance.bool)
    end

    it 'delegates boolean to instance' do
      expect(Flipper.boolean).to eq(Flipper.instance.boolean)
    end

    it 'delegates enable_actor to instance' do
      Flipper.enable_actor(:search, actor)
      expect(Flipper.instance.enabled?(:search, actor)).to be(true)
    end

    it 'delegates disable_actor to instance' do
      Flipper.disable_actor(:search, actor)
      expect(Flipper.instance.enabled?(:search, actor)).to be(false)
    end

    it 'delegates actor to instance' do
      expect(Flipper.actor(actor)).to eq(Flipper.instance.actor(actor))
    end

    it 'delegates enable_group to instance' do
      Flipper.enable_group(:search, group)
      expect(Flipper.instance[:search].enabled_groups).to include(group)
    end

    it 'delegates disable_group to instance' do
      Flipper.disable_group(:search, group)
      expect(Flipper.instance[:search].enabled_groups).to_not include(group)
    end

    it 'delegates enable_percentage_of_actors to instance' do
      Flipper.enable_percentage_of_actors(:search, 5)
      expect(Flipper.instance[:search].percentage_of_actors_value).to be(5)
    end

    it 'delegates disable_percentage_of_actors to instance' do
      Flipper.disable_percentage_of_actors(:search)
      expect(Flipper.instance[:search].percentage_of_actors_value).to be(0)
    end

    it 'delegates actors to instance' do
      expect(Flipper.actors(5)).to eq(Flipper.instance.actors(5))
    end

    it 'delegates percentage_of_actors to instance' do
      expect(Flipper.percentage_of_actors(5)).to eq(Flipper.instance.percentage_of_actors(5))
    end

    it 'delegates enable_percentage_of_time to instance' do
      Flipper.enable_percentage_of_time(:search, 5)
      expect(Flipper.instance[:search].percentage_of_time_value).to be(5)
    end

    it 'delegates disable_percentage_of_time to instance' do
      Flipper.disable_percentage_of_time(:search)
      expect(Flipper.instance[:search].percentage_of_time_value).to be(0)
    end

    it 'delegates time to instance' do
      expect(Flipper.time(56)).to eq(Flipper.instance.time(56))
    end

    it 'delegates percentage_of_time to instance' do
      expect(Flipper.percentage_of_time(56)).to eq(Flipper.instance.percentage_of_time(56))
    end

    it 'delegates features to instance' do
      Flipper.instance.add(:search)
      expect(Flipper.features).to eq(Flipper.instance.features)
      expect(Flipper.features).to include(Flipper.instance[:search])
    end

    it 'delegates feature to instance' do
      expect(Flipper.feature(:search)).to eq(Flipper.instance.feature(:search))
    end

    it 'delegates [] to instance' do
      expect(Flipper[:search]).to eq(Flipper.instance[:search])
    end

    it 'delegates preload to instance' do
      Flipper.instance.enable(:search)
      expect(Flipper.preload([:search])).to eq(Flipper.instance.preload([:search]))
    end

    it 'delegates preload_all to instance' do
      Flipper.instance.enable(:search)
      Flipper.instance.enable(:stats)
      expect(Flipper.preload_all).to eq(Flipper.instance.preload_all)
    end

    it 'delegates add to instance' do
      expect(Flipper.add(:search)).to eq(Flipper.instance.add(:search))
    end

    it 'delegates remove to instance' do
      expect(Flipper.remove(:search)).to eq(Flipper.instance.remove(:search))
    end

    it 'delegates import to instance' do
      other = Flipper.new(Flipper::Adapters::Memory.new)
      other.enable(:search)
      Flipper.import(other)
      expect(Flipper.enabled?(:search)).to be(true)
    end
  end

  describe '.register' do
    it 'adds a group to the group_registry' do
      registry = Flipper::Registry.new
      described_class.groups_registry = registry
      group = described_class.register(:admins, &:admin?)
      expect(registry.get(:admins)).to eq(group)
    end

    it 'adds a group to the group_registry for string name' do
      registry = Flipper::Registry.new
      described_class.groups_registry = registry
      group = described_class.register('admins', &:admin?)
      expect(registry.get(:admins)).to eq(group)
    end

    it 'raises exception if group already registered' do
      described_class.register(:admins) {}

      expect do
        described_class.register(:admins) {}
      end.to raise_error(Flipper::DuplicateGroup, 'Group :admins has already been registered')
    end
  end

  describe '.groups' do
    it 'returns array of group instances' do
      admins = described_class.register(:admins, &:admin?)
      preview_features = described_class.register(:preview_features, &:preview_features?)
      expect(described_class.groups).to eq(Set[
              admins,
              preview_features,
            ])
    end
  end

  describe '.group_names' do
    it 'returns array of group names' do
      described_class.register(:admins, &:admin?)
      described_class.register(:preview_features, &:preview_features?)
      expect(described_class.group_names).to eq(Set[
              :admins,
              :preview_features,
            ])
    end
  end

  describe '.unregister_groups' do
    it 'clear group registry' do
      expect(described_class.groups_registry).to receive(:clear)
      described_class.unregister_groups
    end
  end

  describe '.group_exists' do
    it 'returns true if the group is already created' do
      group = described_class.register('admins', &:admin?)
      expect(described_class.group_exists?(:admins)).to eq(true)
    end

    it 'returns false when the group is not yet registered' do
      expect(described_class.group_exists?(:non_existing)).to eq(false)
    end
  end

  describe '.group' do
    context 'for registered group' do
      before do
        @group = described_class.register(:admins) {}
      end

      it 'returns group' do
        expect(described_class.group(:admins)).to eq(@group)
      end

      it 'returns group with string key' do
        expect(described_class.group('admins')).to eq(@group)
      end
    end

    context 'for unregistered group' do
      before do
        @group = described_class.group(:cats)
      end

      it 'returns group' do
        expect(@group).to be_instance_of(Flipper::Types::Group)
        expect(@group.name).to eq(:cats)
      end

      it 'does not add group to registry' do
        expect(described_class.group_exists?(@group.name)).to be(false)
      end
    end
  end

  describe '.groups_registry' do
    it 'returns a registry instance' do
      expect(described_class.groups_registry).to be_instance_of(Flipper::Registry)
    end
  end

  describe '.groups_registry=' do
    it 'sets groups_registry registry' do
      registry = Flipper::Registry.new
      described_class.groups_registry = registry
      expect(described_class.instance_variable_get('@groups_registry')).to eq(registry)
    end
  end
end
