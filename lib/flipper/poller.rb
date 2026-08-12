require 'logger'
require 'concurrent/utility/monotonic_time'
require 'concurrent/map'
require 'concurrent/atomic/atomic_fixnum'

module Flipper
  class Poller
    attr_reader :adapter, :thread, :interval, :last_synced_at

    def self.instances
      @instances ||= Concurrent::Map.new
    end
    private_class_method :instances

    def self.get(key, options = {})
      instances.compute_if_absent(key) { new(options) }
    end

    def self.reset
      instances.each do |_, instance|
        instance.stop
        instance.thread&.join(1)
      end.clear
    end

    MINIMUM_POLL_INTERVAL = 10

    def initialize(options = {})
      @thread = nil
      @pid = Process.pid
      @mutex = Mutex.new
      @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
      @remote_adapter = options.fetch(:remote_adapter)
      @last_synced_at = Concurrent::AtomicFixnum.new(0)
      @adapter = Adapters::Memory.new(nil, threadsafe: true)
      @shutdown_requested = false

      self.interval = options.fetch(:interval, 10)
      @initial_interval = @interval

      @start_automatically = options.fetch(:start_automatically, true)

      if options.fetch(:shutdown_automatically, true)
        at_exit { stop }
      end
    end

    def start
      ensure_worker_running
    end

    def stop
      @instrumenter.instrument("poller.#{InstrumentationNamespace}", {
        operation: :stop,
      })
      @thread&.kill
    end

    def run
      loop do
        sleep jitter

        begin
          sync
        rescue
          # you can instrument these using poller.flipper
        end

        sleep interval
      end
    end

    def sync
      @instrumenter.instrument("poller.#{InstrumentationNamespace}", operation: :poll) do
        begin
          @adapter.import @remote_adapter
          @last_synced_at.update { |time| Concurrent.monotonic_time }
        ensure
          apply_response_headers
        end
      end
    end

    # Internal: Sets the interval in seconds for how often to poll.
    def interval=(value)
      requested_interval = Flipper::Typecast.to_float(value)
      new_interval = [requested_interval, MINIMUM_POLL_INTERVAL].max

      if requested_interval < MINIMUM_POLL_INTERVAL
        warn "Flipper::Cloud poll interval must be greater than or equal to #{MINIMUM_POLL_INTERVAL} but was #{requested_interval}. Setting interval to #{MINIMUM_POLL_INTERVAL}."
      end

      @interval = new_interval
    end

    private

    def jitter
      rand
    end

    def ensure_worker_running
      # Return early if thread is alive and avoid the mutex lock and unlock.
      return if thread_alive?

      # If another thread is starting worker thread, then return early so this
      # thread can enqueue and move on with life.
      return unless @mutex.try_lock

      begin
        reset_if_forked
        return if @shutdown_requested
        return if thread_alive?
        @thread = Thread.new { run }
        @thread&.report_on_exception = false
        @instrumenter.instrument("poller.#{InstrumentationNamespace}", {
          operation: :thread_start,
        })
      ensure
        @mutex.unlock
      end
    end

    def thread_alive?
      @thread && @thread.alive?
    end

    def reset_if_forked
      return if @pid == Process.pid

      @pid = Process.pid
      @shutdown_requested = false
    end

    def request_shutdown
      @mutex.synchronize do
        reset_if_forked
        @shutdown_requested = true
      end
    end

    def apply_response_headers
      return unless @remote_adapter.respond_to?(:last_get_all_response)

      if response = @remote_adapter.last_get_all_response
        # shutdown based on response header
        if Flipper::Typecast.to_boolean(response["poll-shutdown"])
          request_shutdown
          @instrumenter.instrument("poller.#{InstrumentationNamespace}", {
            operation: :shutdown_requested,
          })
          stop
        end

        # update interval based on response header
        if interval = response["poll-interval"]
          self.interval = [Flipper::Typecast.to_float(interval), @initial_interval].max
        end
      end
    end
  end
end
