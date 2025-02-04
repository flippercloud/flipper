module Flipper
  module Cloud
    class Telemetry
      class BackoffPolicy
        # Private: The default minimum timeout between intervals in milliseconds.
        MIN_TIMEOUT_MS = 30_000

        # Private: The default maximum timeout between intervals in milliseconds.
        MAX_TIMEOUT_MS = 120_000

        # Private: The value to multiply the current interval with for each
        # retry attempt.
        MULTIPLIER = 1.5

        # Private: The randomization factor to use to create a range around the
        # retry interval.
        RANDOMIZATION_FACTOR = 0.5

        # Private
        attr_reader :min_timeout_ms, :max_timeout_ms, :multiplier, :randomization_factor

        # Private
        attr_reader :attempts

        # Public: Create new instance of backoff policy.
        #
        # options - The Hash of options.
        #   :min_timeout_ms - The minimum backoff timeout.
        #   :max_timeout_ms - The maximum backoff timeout.
        #   :multiplier - The value to multiply the current interval with for each
        #                 retry attempt.
        #   :randomization_factor - The randomization factor to use to create a range
        #                           around the retry interval.
        def initialize(options = {})
          @min_timeout_ms = options.fetch(:min_timeout_ms) {
            ENV.fetch("FLIPPER_BACKOFF_MIN_TIMEOUT_MS", MIN_TIMEOUT_MS).to_i
          }
          @max_timeout_ms = options.fetch(:max_timeout_ms) {
            ENV.fetch("FLIPPER_BACKOFF_MAX_TIMEOUT_MS", MAX_TIMEOUT_MS).to_i
          }
          @multiplier = options.fetch(:multiplier) {
            ENV.fetch("FLIPPER_BACKOFF_MULTIPLIER", MULTIPLIER).to_f
          }
          @randomization_factor = options.fetch(:randomization_factor) {
            ENV.fetch("FLIPPER_BACKOFF_RANDOMIZATION_FACTOR", RANDOMIZATION_FACTOR).to_f
          }

          unless @min_timeout_ms >= 0
            raise ArgumentError, ":min_timeout_ms must be >= 0 but was #{@min_timeout_ms.inspect}"
          end

          unless @max_timeout_ms >= 0
            raise ArgumentError, ":max_timeout_ms must be >= 0 but was #{@max_timeout_ms.inspect}"
          end

          unless @min_timeout_ms <= max_timeout_ms
            raise ArgumentError, ":min_timeout_ms (#{@min_timeout_ms.inspect}) must be <= :max_timeout_ms (#{@max_timeout_ms.inspect})"
          end

          @attempts = 0
        end

        # Public: Returns the next backoff interval in milliseconds.
        def next_interval
          interval = @min_timeout_ms * (@multiplier**@attempts)
          interval = add_jitter(interval, @randomization_factor)

          @attempts += 1

          # cap the interval to the max timeout
          result = [interval, @max_timeout_ms].min
          # jitter even when maxed out
          result == @max_timeout_ms ? add_jitter(result, 0.05) : result
        end

        def reset
          @attempts = 0
        end

        private

        def add_jitter(base, randomization_factor)
          random_number = rand
          max_deviation = base * randomization_factor
          deviation = random_number * max_deviation

          if random_number < 0.5
            base - deviation
          else
            base + deviation
          end
        end
      end
    end
  end
end
