require "helper"
require "flipper/adapters/memory"
require "flipper/instrumenters/memory"
require "flipper/adapters/sync/synchronizer"

RSpec.describe Flipper::Adapters::Sync::Synchronizer do
  let(:local) { Flipper::Adapters::Memory.new }
  let(:remote) { Flipper::Adapters::Memory.new }
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }

  subject { described_class.new(local, remote, instrumenter: instrumenter) }

  it "instruments call" do
    subject.call
    events = instrumenter.events.select do |event|
      event.name == "synchronizer_call.flipper"
    end
    expect(events.size).to be(1)
  end

  it "does not raise, but instruments exceptions for visibility" do
    exception = StandardError.new
    expect(remote).to receive(:get_all).and_raise(exception)

    expect { subject.call }.not_to raise_error

    events = instrumenter.events.select do |event|
      event.name == "synchronizer_exception.flipper"
    end
    expect(events.size).to be(1)

    event = events[0]
    expect(event.payload[:exception]).to eq(exception)
  end
end
