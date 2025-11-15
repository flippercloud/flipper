require "flipper/poller"
require "flipper/adapters/http"

RSpec.describe Flipper::Poller do
  let(:url) { "http://app.com/flipper" }
  let(:remote_adapter) { Flipper::Adapters::Http.new(url: url) }
  let(:local) { Flipper.new(subject.adapter) }

  subject do
    described_class.new(
      remote_adapter: remote_adapter,
      start_automatically: false,
      interval: Float::INFINITY
    )
  end

  before do
    stub_request(:get, "#{url}/features?exclude_gate_names=true")
      .to_return(status: 200, body: JSON.generate(features: []))

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
      stub_request(:get, "#{url}/features?exclude_gate_names=true")
        .to_return(status: 200, body: JSON.generate(
          features: [
            {
              key: "polling",
              gates: [
                { key: "boolean", value: true }
              ]
            }
          ]
        ))

      expect(local.enabled?(:polling)).to be(false)
      subject.sync
      expect(local.enabled?(:polling)).to be(true)
    end

    context "when poll-shutdown header is present" do
      before do
        stub_request(:get, "#{url}/features?exclude_gate_names=true")
          .to_return(
            status: 200,
            body: JSON.generate(
              features: [
                {
                  key: "polling",
                  gates: [
                    { key: "boolean", value: true }
                  ]
                }
              ]
            ),
            headers: { "poll-shutdown" => "true" }
          )
      end

      it "stops the poller when poll-shutdown header is true" do
        expect(subject).to receive(:stop).and_call_original
        subject.sync
      end

      it "prevents poller from restarting after shutdown" do
        subject.sync # This should trigger shutdown

        # Try to start again - should be a no-op
        expect(Thread).not_to receive(:new)
        subject.start
      end

      it "instruments the shutdown_requested event" do
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

    context "when poll-shutdown header is present on error response" do
      before do
        stub_request(:get, "#{url}/features?exclude_gate_names=true")
          .to_return(
            status: 404,
            body: JSON.generate({ error: "Not found" }),
            headers: { "poll-shutdown" => "true" }
          )
      end

      it "stops polling even when sync fails with error response" do
        # sync will raise an error, but should still check shutdown header
        expect { subject.sync }.to raise_error(Flipper::Adapters::Http::Error)

        # Verify shutdown was triggered
        expect(Thread).not_to receive(:new)
        subject.start
      end
    end

    context "when poll-shutdown header is false" do
      before do
        stub_request(:get, "#{url}/features?exclude_gate_names=true")
          .to_return(
            status: 200,
            body: JSON.generate(
              features: [
                {
                  key: "polling",
                  gates: [
                    { key: "boolean", value: true }
                  ]
                }
              ]
            ),
            headers: { "poll-shutdown" => "false" }
          )
      end

      it "does not stop the poller" do
        expect(subject).not_to receive(:stop)
        subject.sync
      end
    end

    context "when poll-shutdown header is missing" do
      before do
        stub_request(:get, "#{url}/features?exclude_gate_names=true")
          .to_return(
            status: 200,
            body: JSON.generate(
              features: [
                {
                  key: "polling",
                  gates: [
                    { key: "boolean", value: true }
                  ]
                }
              ]
            )
          )
      end

      it "does not stop the poller" do
        expect(subject).not_to receive(:stop)
        subject.sync
      end
    end

    context "when poll-interval header is present" do
      before do
        stub_request(:get, "#{url}/features?exclude_gate_names=true")
          .to_return(
            status: 200,
            body: JSON.generate(
              features: [
                {
                  key: "polling",
                  gates: [
                    { key: "boolean", value: true }
                  ]
                }
              ]
            ),
            headers: { "poll-interval" => "30" }
          )
      end

      it "adjusts the poll interval" do
        expect(subject.interval).to eq(Float::INFINITY)
        subject.sync
        expect(subject.interval).to eq(30.0)
      end
    end

    context "when poll-interval header is below minimum" do
      before do
        stub_request(:get, "#{url}/features?exclude_gate_names=true")
          .to_return(
            status: 200,
            body: JSON.generate(
              features: [
                {
                  key: "polling",
                  gates: [
                    { key: "boolean", value: true }
                  ]
                }
              ]
            ),
            headers: { "poll-interval" => "5" }
          )
      end

      it "enforces minimum poll interval" do
        subject.sync
        expect(subject.interval).to eq(Flipper::Poller::MINIMUM_POLL_INTERVAL)
      end
    end

    context "when poll-interval header is missing" do
      before do
        stub_request(:get, "#{url}/features?exclude_gate_names=true")
          .to_return(
            status: 200,
            body: JSON.generate(
              features: [
                {
                  key: "polling",
                  gates: [
                    { key: "boolean", value: true }
                  ]
                }
              ]
            )
          )
      end

      it "does not change the interval" do
        original_interval = subject.interval
        subject.sync
        expect(subject.interval).to eq(original_interval)
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
      before do
        stub_request(:get, "#{url}/features?exclude_gate_names=true")
          .to_return(
            status: 200,
            body: JSON.generate(features: []),
            headers: { "poll-shutdown" => "true" }
          )
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
