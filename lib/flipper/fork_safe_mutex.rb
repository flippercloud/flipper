require 'concurrent/atomic/atomic_reference'

module Flipper
  # A Mutex that is safe to use across forks. A forked child inherits a copy of
  # the parent's mutex that may be locked by a thread which no longer exists;
  # unlocking it would raise ThreadError. Instead of unlocking, the first use in
  # a new process atomically swaps in a fresh mutex.
  class ForkSafeMutex
    State = Struct.new(:pid, :mutex)

    def initialize
      @state = Concurrent::AtomicReference.new(State.new(Process.pid, Mutex.new))
    end

    def synchronize(&block)
      mutex.synchronize(&block)
    end

    # Public: The mutex for the current process, swapping in a fresh one if forked.
    def mutex
      current.mutex
    end

    def forked?
      @state.get.pid != Process.pid
    end

    # Public: Swaps in a fresh mutex if forked. Returns true if this call
    # observed the fork, false otherwise.
    def reset_if_forked
      forked = false
      loop do
        state = @state.get
        return forked unless state.pid != Process.pid

        forked = true
        reset(state)
      end
    end

    private

    def current
      loop do
        state = @state.get
        return state unless state.pid != Process.pid

        reset(state)
      end
    end

    def reset(expected)
      @state.compare_and_set(expected, State.new(Process.pid, Mutex.new))
    end
  end
end
