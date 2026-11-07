require "flipper/sem_ver"

module Flipper
  module Expressions
    # Casts a value to a Flipper::SemVer so the comparison expressions order it
    # by semantic version precedence instead of as a string.
    #
    #   { "GreaterThanOrEqualTo" => [{ "SemVer" => [{ "Property" => ["app_version"] }] }, { "SemVer" => ["2.3.1"] }] }
    #
    # Returns nil for anything that isn't a version so a missing or malformed
    # property fails comparisons instead of the check.
    class SemVer
      def self.call(value)
        case value
        when Flipper::SemVer
          value
        when Integer, ::String
          Flipper::SemVer.parse(value.to_s)
        end
      end
    end
  end
end
