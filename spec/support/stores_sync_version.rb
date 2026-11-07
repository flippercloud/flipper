# For adapters that keep the sync version of the flags synced into them, so
# every process sharing the adapter's storage can see it.
RSpec.shared_examples 'an adapter that stores its sync version' do
  let(:version) { Flipper::SyncVersion.new("scope", 10) }

  it 'returns nil before a sync version is recorded' do
    expect(subject.sync_version).to be_nil
  end

  it 'records and replaces the sync version' do
    subject.sync_version = version
    expect(subject.sync_version).to eq(version)

    newer = Flipper::SyncVersion.new("scope", 11)
    subject.sync_version = newer
    expect(subject.sync_version).to eq(newer)
  end

  it 'keeps the sync version out of features and get_all' do
    subject.add(Flipper::Feature.new(:search, subject))
    subject.sync_version = version

    expect(subject.features).to eq(Set["search"])
    expect(subject.get_all.keys).to eq(["search"])
  end

  it 'keeps the sync version when features are removed' do
    feature = Flipper::Feature.new(:search, subject)
    subject.add(feature)
    subject.sync_version = version
    subject.remove(feature)

    expect(subject.sync_version).to eq(version)
  end
end
