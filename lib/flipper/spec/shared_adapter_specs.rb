# Requires the following methods:
# * subject - The instance of the adapter
shared_examples_for 'a flipper adapter' do
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
    subject.name.should_not be_nil
    subject.name.should be_instance_of(Symbol)
  end

  it "has included the flipper adapter module" do
    subject.class.ancestors.should include(Flipper::Adapter)
  end

  it "returns correct default values for the gates if none are enabled" do
    subject.get(feature).should eq({
      :boolean => nil,
      :groups => Set.new,
      :actors => Set.new,
      :percentage_of_actors => nil,
      :percentage_of_time => nil,
    })
  end

  it "can enable, disable and get value for boolean gate" do
    subject.enable(feature, boolean_gate, flipper.boolean).should eq(true)

    result = subject.get(feature)
    result[:boolean].should eq('true')

    subject.disable(feature, boolean_gate, flipper.boolean(false)).should eq(true)

    result = subject.get(feature)
    result[:boolean].should eq(nil)
  end

  it "fully disables all enabled things when boolean gate disabled" do
    actor_22 = actor_class.new('22')
    subject.enable(feature, boolean_gate, flipper.boolean).should eq(true)
    subject.enable(feature, group_gate, flipper.group(:admins)).should eq(true)
    subject.enable(feature, actor_gate, flipper.actor(actor_22)).should eq(true)
    subject.enable(feature, actors_gate, flipper.actors(25)).should eq(true)
    subject.enable(feature, time_gate, flipper.time(45)).should eq(true)

    subject.disable(feature, boolean_gate, flipper.boolean).should eq(true)

    subject.get(feature).should eq({
      :boolean => nil,
      :groups => Set.new,
      :actors => Set.new,
      :percentage_of_actors => nil,
      :percentage_of_time => nil,
    })
  end

  it "can enable, disable and get value for group gate" do
    subject.enable(feature, group_gate, flipper.group(:admins)).should eq(true)
    subject.enable(feature, group_gate, flipper.group(:early_access)).should eq(true)

    result = subject.get(feature)
    result[:groups].should eq(Set['admins', 'early_access'])

    subject.disable(feature, group_gate, flipper.group(:early_access)).should eq(true)
    result = subject.get(feature)
    result[:groups].should eq(Set['admins'])

    subject.disable(feature, group_gate, flipper.group(:admins)).should eq(true)
    result = subject.get(feature)
    result[:groups].should eq(Set.new)
  end

  it "can enable, disable and get value for actor gate" do
    actor_22 = actor_class.new('22')
    actor_asdf = actor_class.new('asdf')

    subject.enable(feature, actor_gate, flipper.actor(actor_22)).should eq(true)
    subject.enable(feature, actor_gate, flipper.actor(actor_asdf)).should eq(true)

    result = subject.get(feature)
    result[:actors].should eq(Set['22', 'asdf'])

    subject.disable(feature, actor_gate, flipper.actor(actor_22)).should eq(true)
    result = subject.get(feature)
    result[:actors].should eq(Set['asdf'])

    subject.disable(feature, actor_gate, flipper.actor(actor_asdf)).should eq(true)
    result = subject.get(feature)
    result[:actors].should eq(Set.new)
  end

  it "can enable, disable and get value for percentage of actors gate" do
    subject.enable(feature, actors_gate, flipper.actors(15)).should eq(true)
    result = subject.get(feature)
    result[:percentage_of_actors].should eq('15')

    subject.disable(feature, actors_gate, flipper.actors(0)).should eq(true)
    result = subject.get(feature)
    result[:percentage_of_actors].should eq('0')
  end

  it "can enable, disable and get value for percentage of time gate" do
    subject.enable(feature, time_gate, flipper.time(10)).should eq(true)
    result = subject.get(feature)
    result[:percentage_of_time].should eq('10')

    subject.disable(feature, time_gate, flipper.time(0)).should eq(true)
    result = subject.get(feature)
    result[:percentage_of_time].should eq('0')
  end

  it "converts boolean value to a string" do
    subject.enable(feature, boolean_gate, flipper.boolean).should eq(true)
    result = subject.get(feature)
    result[:boolean].should eq('true')
  end

  it "converts the actor value to a string" do
    subject.enable(feature, actor_gate, flipper.actor(actor_class.new(22))).should eq(true)
    result = subject.get(feature)
    result[:actors].should eq(Set['22'])
  end

  it "converts group value to a string" do
    subject.enable(feature, group_gate, flipper.group(:admins)).should eq(true)
    result = subject.get(feature)
    result[:groups].should eq(Set['admins'])
  end

  it "converts percentage of time integer value to a string" do
    subject.enable(feature, time_gate, flipper.time(10)).should eq(true)
    result = subject.get(feature)
    result[:percentage_of_time].should eq('10')
  end

  it "converts percentage of actors integer value to a string" do
    subject.enable(feature, actors_gate, flipper.actors(10)).should eq(true)
    result = subject.get(feature)
    result[:percentage_of_actors].should eq('10')
  end

  it "can add, remove and list known features" do
    subject.features.should eq(Set.new)

    subject.add(flipper[:stats]).should eq(true)
    subject.features.should eq(Set['stats'])

    subject.add(flipper[:search]).should eq(true)
    subject.features.should eq(Set['stats', 'search'])

    subject.remove(flipper[:stats]).should eq(true)
    subject.features.should eq(Set['search'])

    subject.remove(flipper[:search]).should eq(true)
    subject.features.should eq(Set.new)
  end

  it "clears all the gate values for the feature on remove" do
    actor_22 = actor_class.new('22')
    subject.enable(feature, boolean_gate, flipper.boolean).should eq(true)
    subject.enable(feature, group_gate, flipper.group(:admins)).should eq(true)
    subject.enable(feature, actor_gate, flipper.actor(actor_22)).should eq(true)
    subject.enable(feature, actors_gate, flipper.actors(25)).should eq(true)
    subject.enable(feature, time_gate, flipper.time(45)).should eq(true)

    subject.remove(feature).should eq(true)

    subject.get(feature).should eq({
      :boolean => nil,
      :groups => Set.new,
      :actors => Set.new,
      :percentage_of_actors => nil,
      :percentage_of_time => nil,
    })
  end

  it "can clear all the gate values for a feature" do
    actor_22 = actor_class.new('22')
    subject.enable(feature, boolean_gate, flipper.boolean).should eq(true)
    subject.enable(feature, group_gate, flipper.group(:admins)).should eq(true)
    subject.enable(feature, actor_gate, flipper.actor(actor_22)).should eq(true)
    subject.enable(feature, actors_gate, flipper.actors(25)).should eq(true)
    subject.enable(feature, time_gate, flipper.time(45)).should eq(true)

    subject.clear(feature).should eq(true)

    subject.get(feature).should eq({
      :boolean => nil,
      :groups => Set.new,
      :actors => Set.new,
      :percentage_of_actors => nil,
      :percentage_of_time => nil,
    })
  end

  it "does not complain clearing a feature that does not exist in adapter" do
    subject.clear(flipper[:stats]).should eq(true)
  end
end
