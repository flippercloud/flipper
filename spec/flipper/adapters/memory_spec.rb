RSpec.describe Flipper::Adapters::Memory do
  let(:source) { {} }

  context 'threadsafe: true' do
    subject { described_class.new(source, threadsafe: true) }

    it_should_behave_like 'a flipper adapter'
  end

  context 'threadsafe: false' do
    subject { described_class.new(source, threadsafe: false) }

    it_should_behave_like 'a flipper adapter'
  end

  describe 'read_integer / set_integer_if_greater' do
    subject { described_class.new }

    it 'returns nil for unknown keys' do
      expect(subject.read_integer(:sync_version)).to be_nil
    end

    it 'sets a new value when none exists' do
      expect(subject.set_integer_if_greater(:sync_version, 100)).to eq(true)
      expect(subject.read_integer(:sync_version)).to eq(100)
    end

    it 'rejects a lower value' do
      subject.set_integer_if_greater(:sync_version, 100)
      expect(subject.set_integer_if_greater(:sync_version, 99)).to eq(false)
      expect(subject.read_integer(:sync_version)).to eq(100)
    end

    it 'rejects an equal value' do
      subject.set_integer_if_greater(:sync_version, 100)
      expect(subject.set_integer_if_greater(:sync_version, 100)).to eq(false)
      expect(subject.read_integer(:sync_version)).to eq(100)
    end

    it 'accepts a strictly greater value' do
      subject.set_integer_if_greater(:sync_version, 100)
      expect(subject.set_integer_if_greater(:sync_version, 200)).to eq(true)
      expect(subject.read_integer(:sync_version)).to eq(200)
    end

    it 'tracks separate keys independently' do
      subject.set_integer_if_greater(:foo, 100)
      subject.set_integer_if_greater(:bar, 50)
      expect(subject.read_integer(:foo)).to eq(100)
      expect(subject.read_integer(:bar)).to eq(50)
    end

    it 'is isolated from get_all and clear' do
      flipper = Flipper.new(subject)
      flipper.enable(:my_feature)
      subject.set_integer_if_greater(:sync_version, 100)

      flipper[:my_feature].clear
      expect(subject.read_integer(:sync_version)).to eq(100)
    end

    it 'imports sync_version from the source adapter' do
      source = described_class.new
      source.set_integer_if_greater(:sync_version, 42)
      Flipper.new(source).enable(:search)

      subject.import(source)

      expect(subject.read_integer(:sync_version)).to eq(42)
    end

    it 'clears sync_version when the source has none' do
      subject.set_integer_if_greater(:sync_version, 100)
      source = described_class.new
      Flipper.new(source).enable(:search)

      subject.import(source)

      expect(subject.read_integer(:sync_version)).to be_nil
    end
  end

  it "can initialize from big hash" do
    flipper = Flipper.new(subject)
    flipper.enable :subscriptions
    flipper.disable :search
    flipper.enable_percentage_of_actors :pro_deal, 20
    flipper.enable_percentage_of_time :logging, 30
    flipper.enable_actor :following, Flipper::Actor.new('1')
    flipper.enable_actor :following, Flipper::Actor.new('3')
    flipper.enable_group :following, Flipper::Types::Group.new(:staff)

    dup = described_class.new(subject.get_all)

    expect(dup.get_all).to eq({
      "subscriptions" => subject.default_config.merge(boolean: "true"),
      "search" => subject.default_config,
      "logging" => subject.default_config.merge(:percentage_of_time => "30"),
      "pro_deal" => subject.default_config.merge(:percentage_of_actors => "20"),
      "following" => subject.default_config.merge(actors: Set["1", "3"], groups: Set["staff"]),
    })
  end
end
