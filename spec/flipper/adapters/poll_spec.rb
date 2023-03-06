require 'flipper/adapters/poll'
require 'flipper/adapters/operation_logger'
require 'active_support/notifications'

RSpec.describe Flipper::Adapters::Poll do
  let(:remote_adapter) do
    Flipper::Adapters::OperationLogger.new Flipper::Adapters::Memory.new
  end
  let(:local_adapter) do
    Flipper::Adapters::OperationLogger.new Flipper::Adapters::Memory.new
  end
  let(:local) { Flipper.new(local_adapter) }
  let(:remote) { Flipper.new(remote_adapter) }
  let(:poll) { Flipper.new(subject) }
  let(:poller) { Flipper::Poller.new(remote_adapter: remote_adapter, start_automatically: false) }

  subject do
    described_class.new(poller, local_adapter)
  end

  it_should_behave_like 'a flipper adapter'

  it 'syncs features with poller has been synced' do
    remote.enable(:search)

    poller.sync # sync poller from remote

    expect(poller.adapter).to receive(:get_all).and_call_original
    expect(poll[:search].boolean_value).to be(true)
    expect(subject.features.sort).to eq(%w(search))
  end

  it 'does not sync features with poller has not been synced' do
    # Perform initial sync
    poller.sync
    subject.features

    # Remote feature enabled, but poller has not synced yet
    remote.enable(:search)
    expect(poller.adapter).to_not receive(:get_all)

    expect(subject.features.sort).to eq(%w())
  end
end
