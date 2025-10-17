require "flipper/poller"
require "flipper/adapters/http"

RSpec.describe Flipper::Poller do
  let(:remote_adapter) { Flipper::Adapters::Memory.new }
  let(:remote) { Flipper.new(remote_adapter) }
  let(:local) { Flipper.new(subject.adapter) }

  subject do
    described_class.new(
      remote_adapter: remote_adapter,
      start_automatically: false,
      interval: Float::INFINITY
    )
  end

  before do
    allow(subject).to receive(:loop).and_yield # Make loop just call once
    allow(subject).to receive(:sleep)          # Disable sleep
    allow(Thread).to receive(:new).and_yield   # Disable separate thread
  end

  describe "#adapter" do
    it "always returns same memory adapter instance" do
      expect(subject.adapter).to be_a(Flipper::Adapters::Memory)
      expect(subject.adapter.object_id).to eq(subject.adapter.object_id)
    end
  end

  describe "#sync" do
    it "syncs remote adapter to local adapter" do
      remote.enable :polling

      expect(local.enabled?(:polling)).to be(false)
      subject.sync
      expect(local.enabled?(:polling)).to be(true)
    end

    context "when poll-shutdown header is present" do
      let(:response) { instance_double(Net::HTTPOK, "[]" => "true") }
      let(:remote_adapter) do
        adapter = Flipper::Adapters::Memory.new
        allow(adapter).to receive(:last_get_all_response).and_return(response)
        adapter
      end

      it "stops the poller when poll-shutdown header is true" do
        remote.enable :polling

        expect(subject).to receive(:stop).and_call_original
        subject.sync
      end

      it "prevents poller from restarting after shutdown" do
        remote.enable :polling

        subject.sync # This should trigger shutdown

        # Try to start again - should be a no-op
        expect(Thread).not_to receive(:new)
        subject.start
      end

      it "stops polling even when sync fails with error response" do
        error_response = instance_double(Net::HTTPNotFound, "[]" => "true", code: "404", body: "{}")
        allow(remote_adapter).to receive(:last_get_all_response).and_return(error_response)
        allow(remote_adapter).to receive(:get_all).and_raise(Flipper::Adapters::Http::Error.new(error_response))

        # sync will raise an error, but should still check shutdown header
        expect { subject.sync }.to raise_error(Flipper::Adapters::Http::Error)

        # Verify shutdown was triggered
        expect(Thread).not_to receive(:new)
        subject.start
      end

      it "instruments the shutdown_requested event" do
        remote.enable :polling

        instrumenter = subject.instance_variable_get(:@instrumenter)

        expect(instrumenter).to receive(:instrument).with(
          "poller.#{Flipper::InstrumentationNamespace}",
          { operation: :poll }
        ).and_call_original

        expect(instrumenter).to receive(:instrument).with(
          "poller.#{Flipper::InstrumentationNamespace}",
          { operation: :shutdown_requested }
        ).and_call_original

        expect(instrumenter).to receive(:instrument).with(
          "poller.#{Flipper::InstrumentationNamespace}",
          { operation: :stop }
        )

        subject.sync
      end
    end

    context "when poll-shutdown header is false" do
      let(:response) { instance_double(Net::HTTPOK, "[]" => "false") }
      let(:remote_adapter) do
        adapter = Flipper::Adapters::Memory.new
        allow(adapter).to receive(:last_get_all_response).and_return(response)
        adapter
      end

      it "does not stop the poller" do
        remote.enable :polling

        expect(subject).not_to receive(:stop)
        subject.sync
      end
    end

    context "when poll-shutdown header is missing" do
      let(:response) { instance_double(Net::HTTPOK, "[]" => nil) }
      let(:remote_adapter) do
        adapter = Flipper::Adapters::Memory.new
        allow(adapter).to receive(:last_get_all_response).and_return(response)
        adapter
      end

      it "does not stop the poller" do
        remote.enable :polling

        expect(subject).not_to receive(:stop)
        subject.sync
      end
    end
  end

  describe "#start" do
    it "starts the poller thread" do
      expect(Thread).to receive(:new).and_yield
      expect(subject).to receive(:loop).and_yield
      expect(subject).to receive(:sync)
      subject.start
    end

    context "after shutdown_requested" do
      let(:response) { instance_double(Net::HTTPOK, "[]" => "true") }
      let(:remote_adapter) do
        adapter = Flipper::Adapters::Memory.new
        allow(adapter).to receive(:last_get_all_response).and_return(response)
        adapter
      end

      it "does not start when shutdown was requested" do
        subject.sync # This triggers shutdown

        expect(Thread).not_to receive(:new)
        subject.start
      end

      it "allows starting after a fork" do
        subject.sync # This triggers shutdown

        # Simulate fork by changing PID
        allow(Process).to receive(:pid).and_return(subject.instance_variable_get(:@pid) + 1)

        # After fork, start should work again
        expect(Thread).to receive(:new).and_yield
        expect(subject).to receive(:loop).and_yield
        expect(subject).to receive(:sync)
        subject.start
      end
    end
  end
end
