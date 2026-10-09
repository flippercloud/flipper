require "flipper/adapters/sync/interval_synchronizer"
require "timeout"

RSpec.describe Flipper::Adapters::Sync::IntervalSynchronizer do
  let(:events) { [] }
  let(:synchronizer) { -> { events << now } }
  let(:interval) { 10 }
  let(:now) { subject.send(:now) }

  subject { described_class.new(synchronizer, interval: interval) }

  it 'synchronizes on first call' do
    expect(events.size).to be(0)
    subject.call
    expect(events.size).to be(1)
  end

  it "retries a failed initial synchronization" do
    attempts = 0
    instance = described_class.new(-> {
      attempts += 1
      raise "unavailable" if attempts == 1
    }, interval: interval)

    expect { instance.call }.to raise_error("unavailable")
    instance.call
    instance.call

    expect(attempts).to eq(2)
  end

  it "recognizes a successful synchronization at time zero" do
    allow(subject).to receive(:now).and_return(0)

    subject.call
    subject.call

    expect(events).to eq([0])
  end

  it "only invokes wrapped synchronizer every interval seconds" do
    subject.call
    events.clear

    # move time to one millisecond less than last sync + interval
    1.upto(interval) do |i|
      allow(subject).to receive(:now).and_return(now + i - 1)
      subject.call
    end
    expect(events.size).to be(0)

    # move time to last sync + interval in milliseconds
    allow(subject).to receive(:now).and_return(now + interval)
    subject.call
    expect(events.size).to be(1)
  end

  it "shares an interval across synchronizers" do
    state = described_class::State.new
    first = described_class.new(-> { events << :first }, interval: interval, state: state)
    second = described_class.new(-> { events << :second }, interval: interval, state: state)

    first.call
    second.call

    expect(events).to eq([:first])
  end

  it "allows reads to continue during a refresh after the initial sync" do
    state = described_class::State.new(synced: true)
    started = Queue.new
    release = Queue.new
    first = described_class.new(-> { started << true; release.pop }, interval: interval, state: state)
    second = described_class.new(-> { events << :second }, interval: interval, state: state)
    future = now + interval
    allow(first).to receive(:now).and_return(future)
    allow(second).to receive(:now).and_return(future)

    refreshing_thread = Thread.new { first.call }
    Timeout.timeout(1) { started.pop }
    reading_thread = Thread.new { second.call }

    expect(reading_thread.join(1)).to be(reading_thread)
    expect(events).to be_empty
  ensure
    release << true if refreshing_thread
    refreshing_thread&.join(1)
  end

  it "consumes polls that started before a coordinated write" do
    state = described_class::State.new(synced: true)
    generation = state.poll_started

    state.synchronize_write { :result }

    expect(state.last_poll_at).to eq(generation)
  end
end
