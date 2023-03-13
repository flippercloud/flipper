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

  subject do
    described_class.new(local_adapter, remote_adapter, key: 'test', start_automatically: false)
  end

  it_should_behave_like 'a flipper adapter'

  it 'syncs features when poller has been synced' do
    remote.enable(:search)

    subject.poller.sync # sync poller from remote

    expect(subject.poller.adapter).to receive(:get_all).and_call_original
    expect(poll[:search].boolean_value).to be(true)
    expect(subject.features.sort).to eq(%w(search))
  end

  it 'writes to both local and remote' do
    poll.enable(:search)

    expect(local[:search].boolean_value).to be(true)
    expect(remote[:search].boolean_value).to be(true)
  end

  it 'does not sync features with poller has not been synced' do
    # Perform initial sync
    subject.poller.sync
    subject.features

    # Remote feature enabled, but poller has not synced yet
    remote.enable(:search)
    expect(subject.poller.adapter).to_not receive(:get_all)

    expect(subject.features.sort).to eq(%w())
  end

  describe '#sync' do
    it "performs initial sync and then does not sync during block" do
      remote.enable(:search)
      subject.poller.sync # Sync poller

      subject.sync do
        expect(poll[:search].boolean_value).to be(true)

        remote.enable(:stats)
        subject.poller.sync # Sync poller

        expect(poll[:stats].boolean_value).to be(false)
      end
    end
  end
end
