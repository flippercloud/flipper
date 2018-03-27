require "helper"
require "flipper/adapters/sync/interval_synchronizer"

RSpec.describe Flipper::Adapters::Sync::IntervalSynchronizer do
  let(:events) { [] }
  let(:synchronizer) { -> { events << described_class.now_ms } }
  let(:interval) { 10 }

  subject { described_class.new(synchronizer, interval: interval) }

  it 'synchronizes on first call' do
    expect(events.size).to be(0)
    subject.call
    expect(events.size).to be(1)
  end

  it "only invokes wrapped synchronizer every interval seconds" do
    now = described_class.now_ms
    subject.call
    events.clear

    # move time to one millisecond less than last sync + interval
    1.upto(interval) do |i|
      allow(described_class).to receive(:now_ms).and_return(now + (i * 1_000) - 1)
      subject.call
    end
    expect(events.size).to be(0)

    # move time to last sync + interval in milliseconds
    allow(described_class).to receive(:now_ms).and_return(now + (interval * 1_000))
    subject.call
    expect(events.size).to be(1)
  end
end
