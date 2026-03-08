require 'flipper/adapters/poll'
require 'flipper/adapters/operation_logger'

RSpec.describe Flipper::Adapters::Poll do
  let(:source_adapter) { Flipper::Adapters::Memory.new }
  let(:source) { Flipper.new(source_adapter, memoize: false) }

  subject do
    described_class.new(source_adapter, {
      key: "poll_spec_#{SecureRandom.hex(4)}",
      start_automatically: false,
      shutdown_automatically: false,
    })
  end

  let(:flipper) { Flipper.new(subject, memoize: false) }

  it_should_behave_like 'a flipper adapter'

  describe '#sync' do
    it 'syncs features from source when poller has synced' do
      source.enable(:search)
      subject.poller.sync

      expect(flipper[:search].boolean_value).to be(true)
    end

    it 'does not sync when poller has not synced since last check' do
      subject.poller.sync
      subject.sync

      source.enable(:search)

      expect(flipper[:search].boolean_value).to be(false)
    end

    it 'suppresses further syncs during block' do
      source.enable(:search)
      subject.poller.sync

      subject.sync do
        expect(flipper[:search].boolean_value).to be(true)

        source.enable(:stats)
        subject.poller.sync

        expect(flipper[:stats].boolean_value).to be(false)
      end

      expect(flipper[:stats].boolean_value).to be(true)
    end
  end

  describe 'writes' do
    it 'writes to both source and local memory' do
      flipper.enable(:search)

      expect(source[:search].boolean_value).to be(true)
      expect(flipper[:search].boolean_value).to be(true)
    end

    it 'add writes to both source and local memory' do
      flipper.add(:search)

      expect(source_adapter.features).to include('search')
      expect(subject.local.features).to include('search')
    end

    it 'remove writes to both source and local memory' do
      flipper.enable(:search)
      flipper.remove(:search)

      expect(source_adapter.features).not_to include('search')
      expect(subject.local.features).not_to include('search')
    end

    it 'clear writes to both source and local memory' do
      flipper.enable(:search)
      subject.clear(flipper[:search])

      expect(source[:search].boolean_value).to be(false)
      expect(flipper[:search].boolean_value).to be(false)
    end

    it 'disable writes to both source and local memory' do
      flipper.enable(:search)
      flipper.disable(:search)

      expect(source[:search].boolean_value).to be(false)
      expect(flipper[:search].boolean_value).to be(false)
    end
  end

  describe '#adapter_stack' do
    it 'includes poll and memory adapter names' do
      stack = subject.adapter_stack
      expect(stack).to include('poll')
      expect(stack).to include('memory')
    end
  end
end
