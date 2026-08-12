require 'concurrent/atomic/atomic_reference'

module Flipper
  # A Mutex that is safe to use across forks. A naive PID-based reset is racy:
  # concurrent first callers in a child can both observe the stale PID, causing
  # one to unlock the mutex acquired by the other. Instead, callers atomically
  # converge on a fresh mutex for the new process.
  class ForkSafeMutex
    State = Struct.new(:pid, :mutex)

    def initialize
      @current = State.new(Process.pid, Mutex.new)
      @state = Concurrent::AtomicReference.new(@current)
    end

    def synchronize(&block)
      state = @current
      state = reset(Process.pid) if state.pid != Process.pid
      state.mutex.synchronize(&block)
    end

    def try_synchronize
      state = @current
      state = reset(Process.pid) if state.pid != Process.pid
      mutex = state.mutex
      return false unless mutex.try_lock

      begin
        yield
        true
      ensure
        mutex.unlock
      end
    end

    def pid
      @current.pid
    end

    def forked?
      @current.pid != Process.pid
    end

    # Public: Swaps in a fresh mutex if forked. Returns true if this call
    # observed the fork, false otherwise.
    def reset_if_forked
      return false unless forked?

      reset(Process.pid)
      true
    end

    private

    def reset(pid)
      loop do
        state = @state.get
        if state.pid == pid
          @current = state
          return state
        end

        replacement = State.new(pid, Mutex.new)
        if @state.compare_and_set(state, replacement)
          @current = replacement
          return replacement
        end

        # Another thread won the reset. Retry so this process uses its state.
      end
    end
  end
end
