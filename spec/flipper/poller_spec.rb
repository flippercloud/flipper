require "flipper/poller"
require "flipper/adapters/http"
require "open3"
require "rbconfig"
require "timeout"

RSpec.describe Flipper::Poller do
  let(:url) { "http://app.com/flipper" }
  let(:remote_adapter) { Flipper::Adapters::Http.new(url: url) }
  let(:local) { Flipper.new(subject.adapter) }

  subject do
    described_class.new(
      remote_adapter: remote_adapter,
      start_automatically: false,
      interval: 3600 # 1 hour
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

    context "when poll-interval header is lower than initial interval" do
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

      it "uses the initial interval as minimum" do
        expect(subject.interval).to eq(3600.0)
        subject.sync
        expect(subject.interval).to eq(3600.0) # Keeps 3600 because it's the initial interval
      end
    end

    context "when poll-interval header is below minimum" do
      subject do
        described_class.new(
          remote_adapter: remote_adapter,
          start_automatically: false,
          interval: 10 # Set initial to minimum
        )
      end

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
        expect(subject.interval).to eq(10.0)
        subject.sync
        # Header says 5, minimum is 10, initial is 10, so max(5->10, 10) = 10
        expect(subject.interval).to eq(Flipper::Poller::MINIMUM_POLL_INTERVAL)
      end
    end

    context "when poll-interval header is higher than initial interval" do
      subject do
        described_class.new(
          remote_adapter: remote_adapter,
          start_automatically: false,
          interval: 20
        )
      end

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
            headers: { "poll-interval" => "60" }
          )
      end

      it "updates to the higher interval from header" do
        expect(subject.interval).to eq(20.0)
        subject.sync
        expect(subject.interval).to eq(60.0) # Uses 60 because it's higher than initial 20
      end
    end

    context "when poll-interval header can decrease back to initial interval" do
      subject do
        described_class.new(
          remote_adapter: remote_adapter,
          start_automatically: false,
          interval: 10
        )
      end

      before do
        # First sync increases interval to 60
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
            headers: { "poll-interval" => "60" }
          ).times(1).then
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
            headers: { "poll-interval" => "10" }
          )
      end

      it "allows interval to go back down to initial after being increased" do
        expect(subject.interval).to eq(10.0)

        # First sync: header says 60, initial is 10, so use 60
        subject.sync
        expect(subject.interval).to eq(60.0)

        # Second sync: header says 10, initial is 10, so use 10
        subject.sync
        expect(subject.interval).to eq(10.0)
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

    it "keeps using its Mutex after a fork" do
      mutex = subject.instance_variable_get(:@mutex)
      allow(Process).to receive(:pid).and_return(Process.pid + 1)

      expect(mutex).to be_instance_of(Mutex)
      expect { subject.start }.not_to raise_error
      expect(subject.instance_variable_get(:@mutex)).to equal(mutex)
    end

    it "updates its process state after a fork" do
      parent_pid = subject.instance_variable_get(:@pid)
      allow(Process).to receive(:pid).and_return(parent_pid + 1)

      subject.start
      expect(subject.instance_variable_get(:@pid)).to eq(parent_pid + 1)
    end

    it "does not expose the raw mutex" do
      expect(subject).not_to respond_to(:mutex)
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

      it "serializes a shutdown request with fork reset" do
        allow(Thread).to receive(:new).and_call_original
        allow(Process).to receive(:pid).and_return(Process.pid + 1)
        mutex = subject.instance_variable_get(:@mutex)
        started = Queue.new
        mutex.lock

        thread = Thread.new do
          started << true
          subject.send(:request_shutdown)
        end
        started.pop

        Timeout.timeout(2) do
          Thread.pass until thread.status == "sleep"
        end
        expect(thread).to be_alive

        mutex.unlock
        thread.join(1)

        expect(subject.instance_variable_get(:@pid)).to eq(Process.pid)
        expect(subject.instance_variable_get(:@shutdown_requested)).to be(true)
      ensure
        mutex&.unlock if mutex&.owned?
        thread&.join(1)
      end

      it "starts one fresh worker in a real forked child" do
        skip "Process.fork is not supported" unless Process.respond_to?(:fork)
        allow(Thread).to receive(:new).and_call_original

        script = <<~'RUBY'
          require "flipper"

          class ForkTestPoller < Flipper::Poller
            def run
              sleep
            end

            def pause_next_start(acquired, release)
              @start_acquired = acquired
              @release_start = release
            end

            private

            def reset_if_forked
              super
              return unless start_acquired = @start_acquired

              @start_acquired = nil
              start_acquired << true
              @release_start.pop
            end
          end

          poller = ForkTestPoller.new(
            remote_adapter: Object.new,
            start_automatically: false,
            shutdown_automatically: false
          )
          poller.start
          parent_worker = poller.thread
          poller.send(:request_shutdown)
          inherited_mutex = poller.instance_variable_get(:@mutex)
          raise "poller does not use Mutex" unless inherited_mutex.instance_of?(Mutex)
          mutex_locked = Queue.new
          release_mutex = Queue.new
          mutex_holder = Thread.new do
            inherited_mutex.lock
            mutex_locked << true
            release_mutex.pop
            inherited_mutex.unlock
          end
          mutex_locked.pop

          begin
            child_pid = fork do
              success = false
              release_start = nil
              first_start = nil
              second_start = nil

              begin
                inherited_worker = poller.thread
                raise "inherited worker is unexpectedly alive" if inherited_worker.alive?

                start_acquired = Queue.new
                release_start = Queue.new
                poller.pause_next_start(start_acquired, release_start)
                first_start = Thread.new { poller.start }
                start_acquired.pop

                second_start = Thread.new { poller.start }
                raise "competing start did not return" unless second_start.join(1)

                release_start << true
                raise "first start did not return" unless first_start.join(1)

                child_worker = poller.thread
                raise "inherited mutex was replaced" unless poller.instance_variable_get(:@mutex).equal?(inherited_mutex)
                raise "worker was not replaced" if child_worker.equal?(inherited_worker)
                raise "replacement worker is not alive" unless child_worker.alive?
                success = true
              rescue => error
                warn error.message
              ensure
                release_start << true if release_start
                first_start&.join(1)
                second_start&.join(1)
                poller.stop
                poller.thread&.join(1)
              end

              exit!(success ? 0 : 1)
            end

            deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
            status = nil
            until status
              if result = Process.wait2(child_pid, Process::WNOHANG)
                _, status = result
              elsif Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
                Process.kill("KILL", child_pid)
                Process.wait(child_pid)
                raise "forked child timed out"
              else
                sleep 0.01
              end
            end
          ensure
            release_mutex << true
            mutex_holder.join(1)
            poller.stop
            parent_worker.join(1)
          end

          exit(status.success? ? 0 : 1)
        RUBY

        _, stderr, status = Open3.capture3(
          RbConfig.ruby,
          "-Ilib",
          "-e",
          script,
          chdir: File.expand_path("../..", __dir__)
        )

        expect(status).to be_success, stderr
      end
    end
  end
end
