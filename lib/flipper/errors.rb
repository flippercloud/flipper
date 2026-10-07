module Flipper
  # Top level error that all other errors inherit from.
  class Error < StandardError; end

  # Raised when gate can not be found for an actor.
  class GateNotFound < Error
    def initialize(actor)
      super "Could not find gate for #{actor.inspect}"
    end
  end

  # Raised when attempting to declare a group name that has already been used.
  class DuplicateGroup < Error; end

  # Raised when attempting to declare a named instance more than once.
  class DuplicateNamedInstance < Error; end

  # Raised when a named instance has not been configured.
  class NamedInstanceNotFound < Error; end

  # Raised when a named instance cannot be exposed as a Flipper method.
  class InvalidNamedInstanceName < Error; end

  # Raised when an invalid value is set to a configuration property
  class InvalidConfigurationValue < Flipper::Error
    def initialize(message = nil)
      default = "Configuration value is not valid."
      super(message || default)
    end
  end
end
