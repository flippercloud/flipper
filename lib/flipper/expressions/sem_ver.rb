module Flipper
  module Expressions
    # Casts a value to a Semantic Version (https://semver.org) so the
    # comparison expressions order it by SemVer 2.0.0 precedence instead of as
    # a string ("2.10.0" > "2.9.0", "1.0.0-beta" < "1.0.0").
    #
    #   { "GreaterThanOrEqualTo" => [{ "SemVer" => [{ "Property" => ["app_version"] }] }, { "SemVer" => ["2.3.1"] }] }
    #
    # Accepts SemVer 2.0.0 strings plus two allowances common in app version
    # strings: an optional leading "v" ("v2.3.1") and missing minor or patch
    # numbers, which count as 0 ("2.3" is 2.3.0). Returns nil for anything
    # else so a missing or malformed property fails comparisons instead of the
    # check. Keep these rules in sync with every other language's SemVer.
    class SemVer
      NUMERIC = /0|[1-9]\d*/
      PRERELEASE_IDENTIFIER = /0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*/
      BUILD_IDENTIFIER = /[0-9a-zA-Z-]+/
      PATTERN = /
        \A[vV]?
        (?<major>#{NUMERIC})
        (?:\.(?<minor>#{NUMERIC}))?
        (?:\.(?<patch>#{NUMERIC}))?
        (?:-(?<prerelease>(?:#{PRERELEASE_IDENTIFIER})(?:\.(?:#{PRERELEASE_IDENTIFIER}))*))?
        (?:\+(?<build>#{BUILD_IDENTIFIER}(?:\.#{BUILD_IDENTIFIER})*))?
        \z
      /x

      def self.call(value)
        case value
        when Version
          value
        when Integer
          parse(value.to_s)
        when ::String
          parse(value)
        end
      end

      def self.parse(string)
        match = PATTERN.match(string)
        return unless match

        prerelease = match[:prerelease].to_s.split(".").map do |identifier|
          identifier.match?(/\A\d+\z/) ? identifier.to_i : identifier
        end

        Version.new(
          major: match[:major].to_i,
          minor: match[:minor].to_i,
          patch: match[:patch].to_i,
          prerelease: prerelease,
          build: match[:build].to_s.split(".")
        )
      end
      private_class_method :parse

      class Version
        include ::Comparable

        attr_reader :major, :minor, :patch, :prerelease, :build

        def initialize(major:, minor:, patch:, prerelease: [], build: [])
          @major = major
          @minor = minor
          @patch = patch
          @prerelease = prerelease.freeze
          @build = build.freeze
          freeze
        end

        # SemVer 2.0.0 precedence. Build metadata is ignored, so 1.0.0+a and
        # 1.0.0+b are equal. Returns nil for anything that isn't a Version,
        # which makes <, >, etc. raise ArgumentError and the comparison
        # expressions return false.
        def <=>(other)
          return unless other.is_a?(Version)

          result = [major, minor, patch] <=> [other.major, other.minor, other.patch]
          return result unless result.zero?

          compare_prerelease(other.prerelease)
        end

        def eql?(other)
          (self <=> other) == 0
        end

        def hash
          [major, minor, patch, prerelease].hash
        end

        def to_s
          string = "#{major}.#{minor}.#{patch}"
          string += "-#{prerelease.join(".")}" if prerelease.any?
          string += "+#{build.join(".")}" if build.any?
          string
        end

        def inspect
          "#<#{self.class.name} #{self}>"
        end

        private

        # A version without a prerelease outranks one with it. Otherwise
        # identifiers compare left to right and a longer list wins a tie.
        def compare_prerelease(other)
          return 0 if prerelease.empty? && other.empty?
          return 1 if prerelease.empty?
          return -1 if other.empty?

          prerelease.zip(other).each do |left, right|
            return 1 if right.nil?

            result = compare_identifier(left, right)
            return result unless result.zero?
          end

          prerelease.length <=> other.length
        end

        # Numeric identifiers compare as numbers and rank below alphanumeric
        # ones, which compare in ASCII order.
        def compare_identifier(left, right)
          if left.is_a?(Integer) && right.is_a?(Integer)
            left <=> right
          elsif left.is_a?(Integer)
            -1
          elsif right.is_a?(Integer)
            1
          else
            left <=> right
          end
        end
      end
    end
  end
end
