module Flipper
  # Top level error that all other errors inherit from.
  class Error < StandardError; end

  # Raised when gate can not be found for an actor.
  class GateNotFound < Error
    def initialize(actor)
      super "Could not find gate for #{actor.inspect}"
    end
  end

  # Raised when writing a feature whose key starts with
  # Flipper::RESERVED_KEY_PREFIX. An ArgumentError, like the adapters' other
  # reserved name errors.
  class ReservedKeyError < ArgumentError
    attr_reader :key

    def initialize(key)
      @key = key.to_s
      super "#{key.to_s.inspect} is reserved for Flipper's internal use and cannot be used as a feature name"
    end
  end

  # Raised when attempting to declare a group name that has already been used.
  class DuplicateGroup < Error; end

  # Raised when an invalid value is set to a configuration property
  class InvalidConfigurationValue < Flipper::Error
    def initialize(message = nil)
      default = "Configuration value is not valid."
      super(message || default)
    end
  end
end
