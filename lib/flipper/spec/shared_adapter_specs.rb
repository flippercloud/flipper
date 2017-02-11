# Requires the following methods:
# * subject - The instance of the adapter
# rubocop:disable Metrics/BlockLength
RSpec.shared_examples_for 'a flipper adapter' do
  let(:actor_class) { Struct.new(:flipper_id) }

  let(:flipper) { Flipper.new(subject) }
  let(:feature) { flipper[:stats] }

  let(:boolean_gate) { feature.gate(:boolean) }
  let(:group_gate)   { feature.gate(:group) }
  let(:actor_gate)   { feature.gate(:actor) }
  let(:actors_gate)  { feature.gate(:percentage_of_actors) }
  let(:time_gate) { feature.gate(:percentage_of_time) }

  before do
    Flipper.register(:admins) do |actor|
      actor.respond_to?(:admin?) && actor.admin?
    end

    Flipper.register(:early_access) do |actor|
      actor.respond_to?(:early_access?) && actor.early_access?
    end
  end

  after do
    Flipper.unregister_groups
  end

  it 'has name that is a symbol' do
    expect(subject.name).not_to be_nil
    expect(subject.name).to be_instance_of(Symbol)
  end

  it 'has included the flipper adapter module' do
    expect(subject.class.ancestors).to include(Flipper::Adapter)
  end

  it "knows version" do
    expect(subject.version).to be(Flipper::Adapter::V1)
  end

  it 'returns correct default values for the gates if none are enabled' do
    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'can enable, disable and get value for boolean gate' do
    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)

    result = subject.get(feature)
    expect(result[:boolean]).to eq('true')

    expect(subject.disable(feature, boolean_gate, flipper.boolean(false))).to eq(true)

    result = subject.get(feature)
    expect(result[:boolean]).to eq(nil)
  end

  it 'fully disables all enabled things when boolean gate disabled' do
    actor22 = actor_class.new('22')
    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, actor_gate, flipper.actor(actor22))).to eq(true)
    expect(subject.enable(feature, actors_gate, flipper.actors(25))).to eq(true)
    expect(subject.enable(feature, time_gate, flipper.time(45))).to eq(true)

    expect(subject.disable(feature, boolean_gate, flipper.boolean(false))).to eq(true)

    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'can enable, disable and get value for group gate' do
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:early_access))).to eq(true)

    result = subject.get(feature)
    expect(result[:groups]).to eq(Set['admins', 'early_access'])

    expect(subject.disable(feature, group_gate, flipper.group(:early_access))).to eq(true)
    result = subject.get(feature)
    expect(result[:groups]).to eq(Set['admins'])

    expect(subject.disable(feature, group_gate, flipper.group(:admins))).to eq(true)
    result = subject.get(feature)
    expect(result[:groups]).to eq(Set.new)
  end

  it 'can enable, disable and get value for actor gate' do
    actor22 = actor_class.new('22')
    actor_asdf = actor_class.new('asdf')

    expect(subject.enable(feature, actor_gate, flipper.actor(actor22))).to eq(true)
    expect(subject.enable(feature, actor_gate, flipper.actor(actor_asdf))).to eq(true)

    result = subject.get(feature)
    expect(result[:actors]).to eq(Set['22', 'asdf'])

    expect(subject.disable(feature, actor_gate, flipper.actor(actor22))).to eq(true)
    result = subject.get(feature)
    expect(result[:actors]).to eq(Set['asdf'])

    expect(subject.disable(feature, actor_gate, flipper.actor(actor_asdf))).to eq(true)
    result = subject.get(feature)
    expect(result[:actors]).to eq(Set.new)
  end

  it 'can enable, disable and get value for percentage of actors gate' do
    expect(subject.enable(feature, actors_gate, flipper.actors(15))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_actors]).to eq('15')

    expect(subject.disable(feature, actors_gate, flipper.actors(0))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_actors]).to eq('0')
  end

  it 'can enable percentage of actors gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.enable(feature, actors_gate, flipper.actors(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_actors]).to eq(percentage.to_s)
    end
  end

  it 'can disable percentage of actors gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.disable(feature, actors_gate, flipper.actors(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_actors]).to eq(percentage.to_s)
    end
  end

  it 'can enable, disable and get value for percentage of time gate' do
    expect(subject.enable(feature, time_gate, flipper.time(10))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_time]).to eq('10')

    expect(subject.disable(feature, time_gate, flipper.time(0))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_time]).to eq('0')
  end

  it 'can enable percentage of time gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.enable(feature, time_gate, flipper.time(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_time]).to eq(percentage.to_s)
    end
  end

  it 'can disable percentage of time gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.disable(feature, time_gate, flipper.time(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_time]).to eq(percentage.to_s)
    end
  end

  it 'converts boolean value to a string' do
    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)
    result = subject.get(feature)
    expect(result[:boolean]).to eq('true')
  end

  it 'converts the actor value to a string' do
    expect(subject.enable(feature, actor_gate, flipper.actor(actor_class.new(22)))).to eq(true)
    result = subject.get(feature)
    expect(result[:actors]).to eq(Set['22'])
  end

  it 'converts group value to a string' do
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    result = subject.get(feature)
    expect(result[:groups]).to eq(Set['admins'])
  end

  it 'converts percentage of time integer value to a string' do
    expect(subject.enable(feature, time_gate, flipper.time(10))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_time]).to eq('10')
  end

  it 'converts percentage of actors integer value to a string' do
    expect(subject.enable(feature, actors_gate, flipper.actors(10))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_actors]).to eq('10')
  end

  it 'can add, remove and list known features' do
    expect(subject.features).to eq(Set.new)

    expect(subject.add(flipper[:stats])).to eq(true)
    expect(subject.features).to eq(Set['stats'])

    expect(subject.add(flipper[:search])).to eq(true)
    expect(subject.features).to eq(Set['stats', 'search'])

    expect(subject.remove(flipper[:stats])).to eq(true)
    expect(subject.features).to eq(Set['search'])

    expect(subject.remove(flipper[:search])).to eq(true)
    expect(subject.features).to eq(Set.new)
  end

  it 'clears all the gate values for the feature on remove' do
    actor22 = actor_class.new('22')
    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, actor_gate, flipper.actor(actor22))).to eq(true)
    expect(subject.enable(feature, actors_gate, flipper.actors(25))).to eq(true)
    expect(subject.enable(feature, time_gate, flipper.time(45))).to eq(true)

    expect(subject.remove(feature)).to eq(true)

    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'can clear all the gate values for a feature' do
    actor22 = actor_class.new('22')
    subject.add(feature)
    expect(subject.features).to include(feature.key)

    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, actor_gate, flipper.actor(actor22))).to eq(true)
    expect(subject.enable(feature, actors_gate, flipper.actors(25))).to eq(true)
    expect(subject.enable(feature, time_gate, flipper.time(45))).to eq(true)

    expect(subject.clear(feature)).to eq(true)
    expect(subject.features).to include(feature.key)
    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'does not complain clearing a feature that does not exist in adapter' do
    expect(subject.clear(flipper[:stats])).to eq(true)
  end

  it 'can get multiple features' do
    expect(subject.add(flipper[:stats])).to eq(true)
    expect(subject.enable(flipper[:stats], boolean_gate, flipper.boolean)).to eq(true)

    expect(subject.add(flipper[:search])).to eq(true)

    result = subject.get_multi([flipper[:stats], flipper[:search], flipper[:other]])
    expect(result).to be_instance_of(Hash)

    stats, search, other = result.values
    expect(stats).to eq(subject.default_config.merge(boolean: 'true'))
    expect(search).to eq(subject.default_config)
    expect(other).to eq(subject.default_config)
  end
end

# Requires the following methods:
# * subject - The instance of the adapter
RSpec.shared_examples_for 'a v2 flipper adapter' do
  let(:actor_class) { Struct.new(:flipper_id) }

  let(:flipper) { Flipper.new(subject) }
  let(:feature) { flipper[:stats] }

  let(:boolean_gate) { feature.gate(:boolean) }
  let(:group_gate)   { feature.gate(:group) }
  let(:actor_gate)   { feature.gate(:actor) }
  let(:actors_gate)  { feature.gate(:percentage_of_actors) }
  let(:time_gate)  { feature.gate(:percentage_of_time) }

  before do
    Flipper.register(:admins) { |actor|
      actor.respond_to?(:admin?) && actor.admin?
    }

    Flipper.register(:early_access) { |actor|
      actor.respond_to?(:early_access?) && actor.early_access?
    }
  end

  after do
    Flipper.unregister_groups
  end

  it "has name that is a symbol" do
    expect(subject.name).to_not be_nil
    expect(subject.name).to be_instance_of(Symbol)
  end

  it "knows version" do
    expect(subject.version).to be(Flipper::Adapter::V2)
  end

  it "has included the flipper adapter module" do
    expect(subject.class.ancestors).to include(Flipper::Adapter)
  end

  it "returns nil when getting key that is not set" do
    expect(subject.get("foo")).to be(nil)
  end

  it "can set, get and delete a key" do
    subject.set("foo", "1")
    expect(subject.get("foo")).to eq("1")
    subject.del("foo")
    expect(subject.get("foo")).to be(nil)
  end

  it "can set already set keys" do
    subject.set("foo", "old")
    expect(subject.get("foo")).to eq("old")
    subject.set("foo", "new")
    expect(subject.get("foo")).to eq("new")
  end

  it "does not error when deleting a missing key" do
    expect(subject.get("foo")).to be(nil)
    subject.del("foo")
  end

  it "always sets value to string" do
    subject.set("foo", 22)
    expect(subject.get("foo")).to eq("22")
  end
end
