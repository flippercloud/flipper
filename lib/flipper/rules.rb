require 'flipper/rules/condition'
require 'flipper/rules/any'
require 'flipper/rules/all'
require 'flipper/rules/property'

module Flipper
  module Rules
    def self.wrap(thing)
      if thing.is_a?(Flipper::Rules::Rule)
        thing
      else
        build(thing)
      end
    end

    def self.build(hash)
      type = const_get(hash.fetch("type"))
      type.build(hash.fetch("value"))
    end

    SUPPORTED_VALUE_TYPES_MAP = {
      String => "string",
      Integer => "integer",
      NilClass => "null",
      TrueClass => "boolean",
      FalseClass => "boolean",
      Array => "array",
    }.freeze

    SUPPORTED_VALUE_TYPES = SUPPORTED_VALUE_TYPES_MAP.keys.freeze

    def self.type_of(object)
      klass, type = SUPPORTED_VALUE_TYPES_MAP.detect { |klass, type| object.is_a?(klass) }
      type
    end

    def self.typed(object)
      type = type_of(object)
      if type.nil?
        raise ArgumentError, "#{object.inspect} is an unsupported type. " +
                             "Object must be one of: #{SUPPORTED_VALUE_TYPES.join(", ")}."
      end
      [type, object]
    end

    def self.require_integer(object)
      raise ArgumentError, "object must be integer" unless object.is_a?(Integer)
      object
    end

    def self.require_array(object)
      raise ArgumentError, "object must be array" unless object.is_a?(Array)
      object
    end
  end
end
