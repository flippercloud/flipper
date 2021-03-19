module Flipper
  # Top level error that all other errors inherit from.
  class Error < StandardError; end

  # Raised when gate can not be found for a thing.
  class GateNotFound < Error
    def initialize(thing)
      super "Could not find gate for #{thing.inspect}"
    end
  end

  # Raised when attempting to declare a group name that has already been used.
  class DuplicateGroup < Error; end

  # Raised when default instance not configured but there is an attempt to
  # use it.
  class DefaultNotSet < Flipper::Error
    def initialize(message = nil)
      warn "Flipper::DefaultNotSet is deprecated and will be removed in 1.0"
      super
    end
  end

  # Raised when an invalid value is set to a configuration property
  class InvalidConfigurationValue < Flipper::Error
    def initialize(message = nil)
      default = "Configuration value is not valid."
      super(message || default)
    end
  end

  # Raised when accessing a configuration property that has been deprecated
  class ConfigurationDeprecated < Flipper::Error
    def initialize(message = nil)
      default = "The configuration property has been deprecated"
      super(message || default)
    end
  end
end
