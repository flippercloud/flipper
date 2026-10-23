require 'logger'
require 'monitor'
require 'concurrent/utility/monotonic_time'
require 'concurrent/map'
require 'concurrent/atomic/atomic_fixnum'
require 'concurrent/atomic/atomic_boolean'

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
      instances.each do |key, instance|
        instance.stop
        instances.delete(key) unless instance.thread&.alive?
      end
    end

    MINIMUM_POLL_INTERVAL = 10
    STOP_JOIN_TIMEOUT = 1

    def initialize(options = {})
      @thread = nil
      @pid = Process.pid
      @mutex = Mutex.new
      @lifecycle_mutex = Monitor.new
      @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
      @remote_adapter = options.fetch(:remote_adapter)
      @last_synced_at = Concurrent::AtomicFixnum.new(0)
      @adapter = Adapters::Memory.new(nil, threadsafe: true)
      @shutdown_requested = false
      @stop_requested = Concurrent::AtomicBoolean.new(false)
      @stop_mutex = Mutex.new
      @stop_condition = ConditionVariable.new

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

      thread_to_stop = @lifecycle_mutex.synchronize do
        @stop_mutex.synchronize do
          @stop_requested.make_true
          @stop_condition.broadcast
          if @thread
            @thread
          else
            @stop_requested.make_false
            nil
          end
        end
      end

      return unless thread_to_stop
      return if thread_to_stop.equal?(Thread.current)

      thread_to_stop.join(STOP_JOIN_TIMEOUT)
      clear_thread_if_current(thread_to_stop) unless thread_to_stop.alive?
    end

    def run
      loop do
        break if stop_requested?

        break if wait_for_stop(jitter)

        begin
          sync
        rescue
          # you can instrument these using poller.flipper
        end
        break if stop_requested?

        break if wait_for_stop(interval)
      end
    ensure
      clear_thread_if_current(Thread.current)
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
        thread = @lifecycle_mutex.synchronize do
          clear_thread_if_current(@thread) if @thread
          @thread = Thread.new { run }
        end
        thread&.report_on_exception = false
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

    def stop_requested?
      @stop_requested.true? || @shutdown_requested
    end

    def clear_thread_if_current(thread)
      @lifecycle_mutex.synchronize do
        return unless @thread.equal?(thread)

        @thread = nil
        @stop_mutex.synchronize do
          @stop_requested.make_false unless @shutdown_requested
        end
      end
    end

    def wait_for_stop(timeout)
      return true if stop_requested?

      deadline = Concurrent.monotonic_time + timeout
      @stop_mutex.synchronize do
        until stop_requested?
          remaining = deadline - Concurrent.monotonic_time
          break if remaining <= 0

          # ConditionVariable#wait can return early (spurious wakeups on
          # JRuby/TruffleRuby), so keep waiting the remaining time until the
          # deadline passes to preserve the configured poll spacing.
          @stop_condition.wait(@stop_mutex, remaining)
        end
        stop_requested?
      end
    end

    def reset_if_forked
      return if @pid == Process.pid

      @pid = Process.pid
      @shutdown_requested = false
      @stop_requested.make_false
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
