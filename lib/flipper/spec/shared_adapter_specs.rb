# Requires the following methods:
# * subject - The instance of the adapter
RSpec.shared_examples_for 'a flipper adapter' do
  let(:flipper) { Flipper.new(subject) }
  let(:feature) { flipper[:stats] }

  let(:boolean_gate)    { feature.gate(:boolean) }
  let(:expression_gate) { feature.gate(:expression) }
  let(:group_gate)      { feature.gate(:group) }
  let(:actor_gate)      { feature.gate(:actor) }
  let(:actors_gate)     { feature.gate(:percentage_of_actors) }
  let(:time_gate)       { feature.gate(:percentage_of_time) }

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

  it 'knows how to get adapter from source' do
    adapter = Flipper::Adapters::Memory.new
    flipper = Flipper.new(adapter)
    expect(subject.class.from(adapter).class.ancestors).to include(Flipper::Adapter)
    expect(subject.class.from(flipper).class.ancestors).to include(Flipper::Adapter)
  end

  it 'returns correct default values for the gates if none are enabled' do
    expect(subject.get(feature)).to eq(subject.class.default_config)
    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'can enable, disable and get value for boolean gate' do
    expect(subject.enable(feature, boolean_gate, Flipper::Types::Boolean.new)).to eq(true)

    result = subject.get(feature)
    expect(result[:boolean]).to eq('true')

    expect(subject.disable(feature, boolean_gate, Flipper::Types::Boolean.new(false))).to eq(true)

    result = subject.get(feature)
    expect(result[:boolean]).to eq(nil)
  end

  it 'fully disables all enabled things when boolean gate disabled' do
    actor22 = Flipper::Actor.new('22')
    expect(subject.enable(feature, boolean_gate, Flipper::Types::Boolean.new)).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, actor_gate, Flipper::Types::Actor.new(actor22))).to eq(true)
    expect(subject.enable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(25))).to eq(true)
    expect(subject.enable(feature, time_gate, Flipper::Types::PercentageOfTime.new(45))).to eq(true)

    expect(subject.disable(feature, boolean_gate, Flipper::Types::Boolean.new(false))).to eq(true)
    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'can enable, disable and get value for expression gate' do
    basic_expression = Flipper.property(:plan).eq("basic")
    age_expression = Flipper.property(:age).gte(21)
    any_expression = Flipper.any(basic_expression, age_expression)

    expect(subject.enable(feature, expression_gate, any_expression)).to eq(true)
    result = subject.get(feature)
    expect(result[:expression]).to eq(any_expression.value)

    expect(subject.enable(feature, expression_gate, basic_expression)).to eq(true)
    result = subject.get(feature)
    expect(result[:expression]).to eq(basic_expression.value)

    expect(subject.disable(feature, expression_gate, basic_expression)).to eq(true)
    result = subject.get(feature)
    expect(result[:expression]).to be(nil)
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
    actor22 = Flipper::Actor.new('22')
    actor_asdf = Flipper::Actor.new('asdf')

    expect(feature.enable(actor22)).to be(true)
    expect(feature.enable(actor_asdf)).to be(true)

    expect(feature).to be_enabled(actor22)
    expect(feature).to be_enabled(actor_asdf)

    expect(feature.disable(actor22)).to be(true)
    expect(feature).not_to be_enabled(actor22)
    expect(feature).to be_enabled(actor_asdf)

    expect(feature.disable(actor_asdf)).to eq(true)
    expect(feature).not_to be_enabled(actor22)
    expect(feature).not_to be_enabled(actor_asdf)
  end

  it 'can enable, disable and get value for percentage of actors gate' do
    expect(subject.enable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(15))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_actors]).to eq('15')

    expect(subject.disable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(0))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_actors]).to eq('0')
  end

  it 'can enable percentage of actors gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.enable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_actors]).to eq(percentage.to_s)
    end
  end

  it 'can disable percentage of actors gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.disable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_actors]).to eq(percentage.to_s)
    end
  end

  it 'can enable, disable and get value for percentage of time gate' do
    expect(subject.enable(feature, time_gate, Flipper::Types::PercentageOfTime.new(10))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_time]).to eq('10')

    expect(subject.disable(feature, time_gate, Flipper::Types::PercentageOfTime.new(0))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_time]).to eq('0')
  end

  it 'can enable percentage of time gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.enable(feature, time_gate, Flipper::Types::PercentageOfTime.new(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_time]).to eq(percentage.to_s)
    end
  end

  it 'can disable percentage of time gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.disable(feature, time_gate, Flipper::Types::PercentageOfTime.new(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_time]).to eq(percentage.to_s)
    end
  end

  it 'converts boolean value to a string' do
    expect(subject.enable(feature, boolean_gate, Flipper::Types::Boolean.new)).to eq(true)
    result = subject.get(feature)
    expect(result[:boolean]).to eq('true')
  end

  it 'converts the actor value to a string' do
    actor = Flipper::Actor.new(22)
    expect(feature).not_to be_enabled(actor)
    feature.enable_actor actor
    expect(feature).to be_enabled(actor)
  end

  it 'converts group value to a string' do
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    result = subject.get(feature)
    expect(result[:groups]).to eq(Set['admins'])
  end

  it 'converts percentage of time integer value to a string' do
    expect(subject.enable(feature, time_gate, Flipper::Types::PercentageOfTime.new(10))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_time]).to eq('10')
  end

  it 'converts percentage of actors integer value to a string' do
    expect(subject.enable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(10))).to eq(true)
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
    actor22 = Flipper::Actor.new('22')
    expect(subject.enable(feature, boolean_gate, Flipper::Types::Boolean.new)).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, actor_gate, Flipper::Types::Actor.new(actor22))).to eq(true)
    expect(subject.enable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(25))).to eq(true)
    expect(subject.enable(feature, time_gate, Flipper::Types::PercentageOfTime.new(45))).to eq(true)

    expect(subject.remove(feature)).to eq(true)

    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'can clear all the gate values for a feature' do
    actor22 = Flipper::Actor.new('22')
    subject.add(feature)
    expect(subject.features).to include(feature.key)

    expect(subject.enable(feature, boolean_gate, Flipper::Types::Boolean.new)).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, actor_gate, Flipper::Types::Actor.new(actor22))).to eq(true)
    expect(subject.enable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(25))).to eq(true)
    expect(subject.enable(feature, time_gate, Flipper::Types::PercentageOfTime.new(45))).to eq(true)

    expect(subject.clear(feature)).to eq(true)
    expect(subject.features).to include(feature.key)
    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'does not complain clearing a feature that does not exist in adapter' do
    expect(subject.clear(flipper[:stats])).to eq(true)
  end

  it 'can get multiple features' do
    expect(subject.add(flipper[:stats])).to eq(true)
    expect(subject.enable(flipper[:stats], boolean_gate, Flipper::Types::Boolean.new)).to eq(true)
    expect(subject.add(flipper[:search])).to eq(true)

    result = subject.get_multi([flipper[:stats], flipper[:search], flipper[:other]])
    expect(result).to be_instance_of(Hash)

    stats = result["stats"]
    search = result["search"]
    other = result["other"]
    expect(stats).to eq(subject.default_config.merge(boolean: 'true'))
    expect(search).to eq(subject.default_config)
    expect(other).to eq(subject.default_config)
  end

  it 'can get all features' do
    expect(subject.add(flipper[:stats])).to eq(true)
    expect(subject.enable(flipper[:stats], boolean_gate, Flipper::Types::Boolean.new)).to eq(true)
    expect(subject.add(flipper[:search])).to eq(true)
    flipper.enable :analytics, Flipper.property(:plan).eq("pro")

    result = subject.get_all

    expect(result).to be_instance_of(Hash)
    expect(result["stats"]).to eq(subject.default_config.merge(boolean: 'true'))
    expect(result["search"]).to eq(subject.default_config)
    expect(result["analytics"]).to eq(subject.default_config.merge(expression: {"Equal"=>[{"Property"=>["plan"]}, "pro"]}))
  end

  it 'includes explicitly disabled features when getting all features' do
    flipper.enable(:stats)
    flipper.enable(:search)
    flipper.disable(:search)

    result = subject.get_all
    expect(result.keys.sort).to eq(%w(search stats))
  end

  it 'can double enable an actor without error' do
    actor = Flipper::Actor.new('Flipper::Actor;22')
    expect(feature.enable(actor)).to be(true)
    expect(feature.enable(actor)).to be(true)
    expect(feature).to be_enabled(actor)
  end

  it 'can double enable a group without error' do
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.get(feature).fetch(:groups)).to eq(Set['admins'])
  end

  it 'can double enable percentage without error' do
    expect(subject.enable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(25))).to eq(true)
    expect(subject.enable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(25))).to eq(true)
  end

  it 'can double enable without error' do
    expect(subject.enable(feature, boolean_gate, Flipper::Types::Boolean.new)).to eq(true)
    expect(subject.enable(feature, boolean_gate, Flipper::Types::Boolean.new)).to eq(true)
  end

  it 'can get_all features when there are none' do
    expect(subject.features).to eq(Set.new)
    expect(subject.get_all).to eq({})
  end

  it 'clears other gate values on enable' do
    actor = Flipper::Actor.new('Flipper::Actor;22')
    subject.enable(feature, actors_gate, Flipper::Types::PercentageOfActors.new(25))
    subject.enable(feature, time_gate, Flipper::Types::PercentageOfTime.new(25))
    subject.enable(feature, group_gate, flipper.group(:admins))
    subject.enable(feature, actor_gate, Flipper::Types::Actor.new(actor))
    subject.enable(feature, boolean_gate, Flipper::Types::Boolean.new(true))
    expect(subject.get(feature)).to eq(subject.default_config.merge(boolean: "true"))
  end

  it 'can import and export' do
    adapter = Flipper::Adapters::Memory.new
    source_flipper = Flipper.new(adapter)
    source_flipper.enable(:stats)
    export = adapter.export

    # some adapters cannot import so if they return false lets assert it
    # didn't happen
    if subject.import(export)
      expect(flipper[:stats]).to be_enabled
    else
      expect(flipper[:stats]).not_to be_enabled
    end
  end
end
