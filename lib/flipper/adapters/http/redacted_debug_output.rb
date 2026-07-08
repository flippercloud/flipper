module Flipper
  module Adapters
    class Http
      # Wraps the IO-like object passed to Net::HTTP#set_debug_output and
      # redacts the values of sensitive request headers (auth tokens, etc.)
      # before they are written. Without this, enabling debug output dumps the
      # raw request — including the flipper-cloud-token bearer credential — in
      # cleartext to STDOUT/logs.
      class RedactedDebugOutput
        # Header names whose values must never reach debug output.
        SENSITIVE_HEADERS = %w[
          flipper-cloud-token
          authorization
        ].freeze

        REDACTED = "[REDACTED]".freeze

        # Matches "<sensitive-header>: <value>" up to (but not including) the
        # next line terminator. Net::HTTP writes request headers via
        # String#dump, so line breaks appear as the escaped "\r\n" sequence; the
        # value char class excludes backslash and quote so it stops there. Raw
        # CRLFs and a closing quote are handled too, just in case.
        PATTERN = Regexp.new(
          '((?:' + Regexp.union(SENSITIVE_HEADERS).source + '):[ \t]*)' +
          '[^\r\n"\\\\]*' +
          '(?=\\\\r|\r|\n|"|\z)',
          Regexp::IGNORECASE
        )

        # Wraps output unless it is nil or already wrapped.
        def self.wrap(output)
          return output if output.nil? || output.is_a?(self)
          new(output)
        end

        def self.redact(message)
          return message unless message.is_a?(String)
          message.gsub(PATTERN) { "#{$1}#{REDACTED}" }
        end

        def initialize(output)
          @output = output
        end

        def <<(message)
          @output << self.class.redact(message)
          self
        end

        private

        # Behave like the wrapped output for anything Net::HTTP doesn't route
        # through <<.
        def method_missing(name, *args, &block)
          if @output.respond_to?(name)
            @output.public_send(name, *args, &block)
          else
            super
          end
        end

        def respond_to_missing?(name, include_private = false)
          @output.respond_to?(name, include_private) || super
        end
      end
    end
  end
end
