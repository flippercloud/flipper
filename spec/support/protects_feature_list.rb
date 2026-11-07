# For adapters that store the feature list under the key flipper_features,
# next to the feature data. Including specs define `add_reserved_name_to_list`,
# which puts "flipper_features" in the list the way older versions did.
RSpec.shared_examples 'an adapter that protects its feature list' do
  let(:feature) { Flipper::Feature.new(:flipper_features, subject) }
  let(:boolean) { feature.gate(:boolean) }

  before { subject.add(Flipper::Feature.new(:search, subject)) }

  it 'refuses writes to a feature named flipper_features' do
    [
      -> { subject.add(feature) },
      -> { subject.enable(feature, boolean, Flipper::Types::Boolean.new(true)) },
      -> { subject.disable(feature, boolean, Flipper::Types::Boolean.new(false)) },
      -> { subject.clear(feature) },
    ].each do |write|
      expect(&write).to raise_error(ArgumentError, /"flipper_features" is reserved/)
    end

    expect(subject.features).to eq(Set["search"])
    expect(subject.get_all.keys).to eq(["search"])
  end

  it 'removes a flipper_features entry from the list without deleting the list' do
    add_reserved_name_to_list
    expect(subject.features).to eq(Set["search", "flipper_features"])

    expect(subject.remove(feature)).to be(true)

    expect(subject.features).to eq(Set["search"])
    expect(subject.get_all.keys).to eq(["search"])
  end
end

# For adapters that store the sync version under flipper_features:sync_version,
# next to the feature data.
RSpec.shared_examples 'an adapter that protects its sync version key' do
  let(:feature) { Flipper::Feature.new("flipper_features:sync_version", subject) }
  let(:boolean) { feature.gate(:boolean) }
  let(:version) { Flipper::SyncVersion.new("scope", 10) }

  before { subject.sync_version = version }

  it 'refuses writes to a feature named after the sync version key' do
    [
      -> { subject.add(feature) },
      -> { subject.enable(feature, boolean, Flipper::Types::Boolean.new(true)) },
      -> { subject.disable(feature, boolean, Flipper::Types::Boolean.new(false)) },
      -> { subject.clear(feature) },
    ].each do |write|
      expect(&write).to raise_error(ArgumentError, /"flipper_features:sync_version" is reserved/)
    end

    expect(subject.sync_version).to eq(version)
  end

  it 'keeps the sync version when that feature is removed' do
    expect(subject.remove(feature)).to be(true)
    expect(subject.sync_version).to eq(version)
  end
end

# For adapters that store the sync version as a gate row of a reserved feature
# key. A real feature with that key keeps its gates and doesn't change the
# stored version.
RSpec.shared_examples 'an adapter that keeps its sync version apart from features' do
  let(:feature) { Flipper::Feature.new("__flipper_sync_version__", subject) }
  let(:version) { Flipper::SyncVersion.new("scope", 10) }

  it 'keeps the sync version and the feature separate' do
    flipper = Flipper.new(subject)
    flipper.enable(feature.key)
    flipper.enable_actor(feature.key, Flipper::Actor.new("User;1"))

    subject.sync_version = version
    subject.sync_version = Flipper::SyncVersion.new("scope", 11)

    expect(subject.sync_version).to eq(Flipper::SyncVersion.new("scope", 11))
    expect(flipper.enabled?(feature.key)).to be(true)
    expect(flipper[feature.key].actors_value).to eq(Set["User;1"])
    expect(subject.get(feature).keys).not_to include(:sync_version)
  end
end
