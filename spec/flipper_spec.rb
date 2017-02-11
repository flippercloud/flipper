require 'helper'

RSpec.describe Flipper do
  describe ".new" do
    it "returns new instance of dsl" do
      instance = described_class.new(double('Adapter', version: Flipper::Adapter::V1))
      expect(instance).to be_instance_of(Flipper::DSL)
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

  describe '.unregister_groups' do
    it 'clear group registry' do
      expect(described_class.groups_registry).to receive(:clear)
      described_class.unregister_groups
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
      it 'raises group not registered error' do
        expect do
          described_class.group(:cats)
        end.to raise_error(Flipper::GroupNotRegistered, 'Group :cats has not been registered')
      end
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
end
