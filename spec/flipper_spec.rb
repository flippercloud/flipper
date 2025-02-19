require 'flipper/cloud'

RSpec.describe Flipper do
  describe '.new' do
    it 'returns new instance of dsl' do
      instance = described_class.new(double('Adapter'))
      expect(instance).to be_instance_of(Flipper::DSL)
    end
  end

  describe '.configure' do
    it 'yield configuration instance' do
      described_class.configure do |config|
        expect(config).to be_instance_of(Flipper::Configuration)
      end
    end
  end

  describe '.configuration' do
    it 'returns configuration instance' do
      expect(described_class.configuration).to be_instance_of(Flipper::Configuration)
    end
  end

  describe '.configuration=' do
    it "sets configuration instance" do
      configuration = Flipper::Configuration.new
      described_class.configuration = configuration
      expect(described_class.configuration).to be(configuration)
    end
  end

  describe '.instance' do
    it 'returns DSL instance using result of default invocation' do
      instance = described_class.new(Flipper::Adapters::Memory.new)
      described_class.configure do |config|
        config.default { instance }
      end
      expect(described_class.instance).to be(instance)
      expect(described_class.instance).to be(described_class.instance) # memoized
    end

    it 'is reset when configuration is changed' do
      described_class.configure do |config|
        config.default { described_class.new(Flipper::Adapters::Memory.new) }
      end
      original_instance = described_class.instance

      new_config = Flipper::Configuration.new
      new_config.default { described_class.new(Flipper::Adapters::Memory.new) }
      described_class.configuration = new_config

      expect(described_class.instance).not_to be(original_instance)
    end
  end

  describe '.instance=' do
    it 'updates Flipper.instance' do
      instance = described_class.new(Flipper::Adapters::Memory.new)
      described_class.instance = instance
      expect(described_class.instance).to be(instance)
    end
  end

  describe "delegation to instance" do
    let(:group) { Flipper::Types::Group.new(:admins) }
    let(:actor) {
      Flipper::Actor.new("1", {
        "plan" => "basic",
      })
    }
    let(:expression) { Flipper.property(:plan).eq("basic") }

    before do
      described_class.configure do |config|
        config.default { described_class.new(Flipper::Adapters::Memory.new) }
      end
    end

    it 'delegates enabled? to instance' do
      expect(described_class.enabled?(:search)).to eq(described_class.instance.enabled?(:search))
      described_class.instance.enable(:search)
      expect(described_class.enabled?(:search)).to eq(described_class.instance.enabled?(:search))
    end

    it 'delegates enable to instance' do
      described_class.enable(:search)
      expect(described_class.instance.enabled?(:search)).to be(true)
    end

    it 'delegates disable to instance' do
      described_class.disable(:search)
      expect(described_class.instance.enabled?(:search)).to be(false)
    end

    it 'delegates expression to instance' do
      expect(described_class.expression(:search)).to be(nil)

      expression = Flipper.property(:plan).eq("basic")
      Flipper.instance.enable_expression :search, expression

      expect(described_class.expression(:search)).to eq(expression)
    end

    it 'delegates enable_expression to instance' do
      described_class.enable_expression(:search, expression)
      expect(described_class.instance.enabled?(:search, actor)).to be(true)
    end

    it 'delegates disable_expression to instance' do
      described_class.disable_expression(:search)
      expect(described_class.instance.enabled?(:search, actor)).to be(false)
    end

    it 'delegates add_expression to instance' do
      described_class.add_expression(:search, expression)
      expect(described_class.instance.enabled?(:search, actor)).to be(true)
    end

    it 'delegates remove_expression to instance' do
      described_class.enable_expression(:search, Flipper.any(expression))
      expect(described_class.instance.enabled?(:search, actor)).to be(true)
      described_class.remove_expression(:search, expression)
      expect(described_class.instance.enabled?(:search, actor)).to be(false)
    end

    it 'delegates enable_actor to instance' do
      described_class.enable_actor(:search, actor)
      expect(described_class.instance.enabled?(:search, actor)).to be(true)
    end

    it 'delegates disable_actor to instance' do
      described_class.disable_actor(:search, actor)
      expect(described_class.instance.enabled?(:search, actor)).to be(false)
    end

    it 'delegates enable_group to instance' do
      described_class.enable_group(:search, group)
      expect(described_class.instance[:search].enabled_groups).to include(group)
    end

    it 'delegates disable_group to instance' do
      described_class.disable_group(:search, group)
      expect(described_class.instance[:search].enabled_groups).not_to include(group)
    end

    it 'delegates enable_percentage_of_actors to instance' do
      described_class.enable_percentage_of_actors(:search, 5)
      expect(described_class.instance[:search].percentage_of_actors_value).to be(5)
    end

    it 'delegates disable_percentage_of_actors to instance' do
      described_class.disable_percentage_of_actors(:search)
      expect(described_class.instance[:search].percentage_of_actors_value).to be(0)
    end

    it 'delegates enable_percentage_of_time to instance' do
      described_class.enable_percentage_of_time(:search, 5)
      expect(described_class.instance[:search].percentage_of_time_value).to be(5)
    end

    it 'delegates disable_percentage_of_time to instance' do
      described_class.disable_percentage_of_time(:search)
      expect(described_class.instance[:search].percentage_of_time_value).to be(0)
    end

    it 'delegates features to instance' do
      described_class.instance.add(:search)
      expect(described_class.features).to eq(described_class.instance.features)
      expect(described_class.features).to include(described_class.instance[:search])
    end

    it 'delegates feature to instance' do
      expect(described_class.feature(:search)).to eq(described_class.instance.feature(:search))
    end

    it 'delegates [] to instance' do
      expect(described_class[:search]).to eq(described_class.instance[:search])
    end

    it 'delegates preload to instance' do
      described_class.instance.enable(:search)
      expect(described_class.preload([:search])).to eq(described_class.instance.preload([:search]))
    end

    it 'delegates preload_all to instance' do
      described_class.instance.enable(:search)
      described_class.instance.enable(:stats)
      expect(described_class.preload_all).to eq(described_class.instance.preload_all)
    end

    it 'delegates add to instance' do
      expect(described_class.add(:search)).to eq(described_class.instance.add(:search))
    end

    it 'delegates exist? to instance' do
      expect(described_class.exist?(:search)).to eq(described_class.instance.exist?(:search))
    end

    it 'delegates remove to instance' do
      expect(described_class.remove(:search)).to eq(described_class.instance.remove(:search))
    end

    it 'delegates import to instance' do
      other = described_class.new(Flipper::Adapters::Memory.new)
      other.enable(:search)
      described_class.import(other)
      expect(described_class.enabled?(:search)).to be(true)
    end

    it 'delegates export to instance' do
      described_class.enable(:search)
      expect(described_class.export).to eq(described_class.adapter.export)
      expect(described_class.export(format: :json)).to eq(described_class.adapter.export(format: :json))
    end

    it 'delegates adapter to instance' do
      expect(described_class.adapter).to eq(described_class.instance.adapter)
    end

    it 'delegates memoize= to instance' do
      expect(described_class.adapter.memoizing?).to be(false)
      described_class.memoize = true
      expect(described_class.adapter.memoizing?).to be(true)
    end

    it 'delegates memoizing? to instance' do
      expect(described_class.memoizing?).to eq(described_class.adapter.memoizing?)
    end

    it 'delegates read_only? to instance' do
      expect(described_class.read_only?).to eq(described_class.adapter.read_only?)
    end

    it 'delegates sync stuff to instance and does nothing' do
      expect(described_class.sync).to be(nil)
      expect(described_class.sync_secret).to be(nil)
    end

    it 'delegates sync stuff to instance for Flipper::Cloud' do
      stub = stub_request(:get, "https://www.flippercloud.io/adapter/features?exclude_gate_names=true").
        with({
          headers: {
            'flipper-cloud-token'=>'asdf',
          },
        }).to_return(status: 200, body: '{"features": {}}', headers: {})
      cloud_configuration = Flipper::Cloud::Configuration.new({
        token: "asdf",
        sync_secret: "tasty",
      })

      described_class.configure do |config|
        config.default { Flipper::Cloud::DSL.new(cloud_configuration) }
      end
      described_class.sync
      expect(described_class.sync_secret).to eq("tasty")
      expect(stub).to have_been_requested
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
      described_class.register('admins', &:admin?)
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

  describe ".constant" do
    it "returns Flipper::Expression::Constant instance" do
      expect(described_class.constant(false)).to eq(Flipper::Expression::Constant.new(false))
      expect(described_class.constant("string")).to eq(Flipper::Expression::Constant.new("string"))
    end
  end

  describe ".property" do
    it "returns Flipper::Expressions::Property expression" do
      expect(Flipper.property("name")).to eq(Flipper::Expression.build(Property: "name"))
    end
  end

  describe ".boolean" do
    it "returns Flipper::Expressions::Boolean expression" do
      expect(described_class.boolean(true)).to eq(Flipper::Expression.build(Boolean: true))
      expect(described_class.boolean(false)).to eq(Flipper::Expression.build(Boolean: false))
    end
  end

  describe ".random" do
    it "returns Flipper::Expressions::Random expression" do
      expect(Flipper.random(100)).to eq(Flipper::Expression.build(Random: 100))
    end
  end

  describe ".any" do
    let(:age_expression) { Flipper.property(:age).gte(21) }
    let(:plan_expression) { Flipper.property(:plan).eq("basic") }

    it "returns Flipper::Expressions::Any instance" do
      expect(Flipper.any(age_expression, plan_expression)).to eq(
        Flipper::Expression.build({Any: [age_expression, plan_expression]})
      )
    end
  end

  describe ".all" do
    let(:age_expression) { Flipper.property(:age).gte(21) }
    let(:plan_expression) { Flipper.property(:plan).eq("basic") }

    it "returns Flipper::Expressions::All instance" do
      expect(Flipper.all(age_expression, plan_expression)).to eq(
        Flipper::Expression.build({All: [age_expression, plan_expression]})
      )
    end
  end
end
