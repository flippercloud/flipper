require 'set'
require "flipper/serializers/json"
require "flipper/serializers/gzip"

module Flipper
  class Typecast
    TRUTH_MAP = {
      true    => true,
      1       => true,
      'true'  => true,
      '1'     => true,
    }.freeze

    # Internal: Convert value to a boolean.
    #
    # Returns true or false.
    def self.to_boolean(value)
      !!TRUTH_MAP[value]
    end

    # Internal: Convert value to an integer.
    #
    # Returns an Integer representation of the value.
    # Raises ArgumentError if conversion is not possible.
    def self.to_integer(value)
      value.to_i
    rescue NoMethodError
      raise ArgumentError, "#{value.inspect} cannot be converted to an integer"
    end

    # Internal: Convert value to a float.
    #
    # Returns a Float representation of the value.
    # Raises ArgumentError if conversion is not possible.
    def self.to_float(value)
      value.to_f
    rescue NoMethodError
      raise ArgumentError, "#{value.inspect} cannot be converted to a float"
    end

    # Internal: Convert value to a number.
    #
    # Returns a Integer or Float representation of the value.
    # Raises ArgumentError if conversion is not possible.
    def self.to_number(value)
      case value
      when Numeric
        value
      when String
        value.include?('.') ? to_float(value) : to_integer(value)
      when NilClass
        0
      else
        value.to_f
      end
    rescue NoMethodError
      raise ArgumentError, "#{value.inspect} cannot be converted to a number"
    end
    singleton_class.send(:alias_method, :to_percentage, :to_number)

    # Internal: Convert value to a set.
    #
    # Returns a Set representation of the value.
    # Raises ArgumentError if conversion is not possible.
    def self.to_set(value)
      return value if value.is_a?(Set)
      return Set.new if value.nil? || value.empty?

      if value.respond_to?(:to_set)
        value.to_set
      else
        raise ArgumentError, "#{value.inspect} cannot be converted to a set"
      end
    end

    # Internal: Convert value to a feature name usable as a feature key.
    # Removes invisible format/control characters (zero-width spaces,
    # joiners, BOM, etc.) that make visually identical but distinct names,
    # and trims unicode whitespace (e.g. non-breaking space) that
    # String#strip misses. Visible characters are left untouched.
    #
    # Returns a String.
    def self.to_feature_name(value)
      # U+2800 renders as a fixed-width blank but is not default-ignorable or whitespace.
      to_utf8(value.to_s)
           .scrub('')
           .gsub(/[\p{Default_Ignorable_Code_Point}\p{Cc}\u2800]/, '')
           .gsub(/\A[[:space:]]+|[[:space:]]+\z/, '')
    end

    # Private: Convert a string to UTF-8 so the unicode regexps above can
    # match it. Binary strings are read as UTF-8, leaving scrub to drop
    # invalid bytes. Encodings with no UTF-8 converter are read as UTF-8 only
    # when their bytes are valid UTF-8, otherwise the name becomes empty.
    def self.to_utf8(value)
      return value if value.encoding == Encoding::UTF_8 || value.ascii_only?
      return String.new(value, encoding: Encoding::UTF_8) if value.encoding == Encoding::BINARY

      value.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '')
    rescue Encoding::ConverterNotFoundError
      utf8 = String.new(value, encoding: Encoding::UTF_8)
      utf8.valid_encoding? ? utf8 : ''
    end
    private_class_method :to_utf8

    def self.features_hash(source)
      normalized_source = {}
      (source || {}).each do |feature_key, gates|
        normalized_source[feature_key] ||= {}
        gates.each do |gate_key, value|
          normalized_value = case value
          when Array, Set
            value.to_set
          when Hash
            value
          else
            value ? value.to_s : value
          end
          normalized_source[feature_key][gate_key.to_sym] = normalized_value
        end
      end
      normalized_source
    end

    def self.to_json(source)
      Serializers::Json.serialize(source)
    end

    def self.from_json(source)
      Serializers::Json.deserialize(source)
    end

    def self.to_gzip(source)
      Serializers::Gzip.serialize(source)
    end

    def self.from_gzip(source)
      Serializers::Gzip.deserialize(source)
    end
  end
end
