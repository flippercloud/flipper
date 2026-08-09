require 'concurrent/atomic/atomic_reference'

module Flipper
  # A Mutex that is safe to use across forks. A forked child inherits a copy of
  # the parent's mutex that may be locked by a thread which no longer exists;
  # unlocking it would raise ThreadError. Instead of unlocking, the first use in
  # a new process atomically swaps in a fresh mutex.
  class ForkSafeMutex
    State = Struct.new(:pid, :mutex)

    def initialize
      @current = State.new(Process.pid, Mutex.new)
      @state = Concurrent::AtomicReference.new(@current)
    end

    def synchronize(&block)
      current.mutex.synchronize(&block)
    end

    def try_synchronize
      mutex = current.mutex
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

      current
      true
    end

    private

    def current
      state = @current
      pid = Process.pid
      return state if state.pid == pid

      reset(pid)
    end

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
