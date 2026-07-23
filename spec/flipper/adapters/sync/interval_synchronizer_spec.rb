require "flipper/adapters/sync/interval_synchronizer"

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

  it "does not synchronize again while a claimed interval sync is in flight" do
    entered = Queue.new
    release = Queue.new
    synchronizer = -> do
      events << now
      entered << true
      release.pop
    end
    instance = described_class.new(synchronizer, interval: interval)

    allow(instance).to receive(:now).and_return(interval)

    first_thread = Thread.new { instance.call }
    entered.pop

    threads = 10.times.map { Thread.new { instance.call } }
    sleep 0.05

    expect(events.size).to eq(1)

    release << true
    ([first_thread] + threads).each(&:join)

    expect(events.size).to eq(1)
  end

  it "does not synchronize again when the interval passes during an in-flight sync" do
    current_time = interval
    entered = Queue.new
    release = Queue.new
    synchronizer = -> do
      events << current_time
      entered << true
      release.pop
    end
    instance = described_class.new(synchronizer, interval: interval)

    allow(instance).to receive(:now) { current_time }

    first_thread = Thread.new { instance.call }
    entered.pop

    current_time += interval
    second_thread = Thread.new { instance.call }
    sleep 0.05

    expect(events.size).to eq(1)

    release << true
    [first_thread, second_thread].each(&:join)

    expect(events.size).to eq(1)
  end

  it "resets in-flight synchronization state after a fork" do
    instance = described_class.new(synchronizer, interval: interval)
    instance.instance_variable_set(:@syncing, true)

    allow(instance).to receive(:now).and_return(interval)
    allow(Process).to receive(:pid).and_return(instance.instance_variable_get(:@pid) + 1)

    instance.call

    expect(events.size).to eq(1)
  end
end
