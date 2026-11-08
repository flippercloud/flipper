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

# For adapters that store the sync version next to the feature data, under
# Flipper::SyncVersion::KEY. Writes to that name or any other __flipper name
# are refused.
RSpec.shared_examples 'an adapter that protects its sync version key' do
  let(:reserved_name) { Flipper::SyncVersion::KEY }
  let(:feature) { Flipper::Feature.new(reserved_name, subject) }
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
      expect(&write).to raise_error(Flipper::ReservedKeyError, /#{Regexp.escape(reserved_name.inspect)} is reserved/)
    end
    expect { subject.add(Flipper::Feature.new("__flipper_other", subject)) }.to raise_error(Flipper::ReservedKeyError)

    expect(subject.features).to eq(Set.new)
    expect(subject.sync_version).to eq(version)
  end

  it 'keeps the sync version when that feature is removed' do
    expect(subject.remove(feature)).to be(true)
    expect(subject.sync_version).to eq(version)
  end
end
