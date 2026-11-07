module Flipper
  # A Semantic Version (https://semver.org) ordered by SemVer 2.0.0 precedence,
  # so "2.10.0" > "2.9.0" and "1.0.0-beta" < "1.0.0".
  #
  # Parses SemVer 2.0.0 strings plus two allowances common in app version
  # strings: an optional leading "v" ("v2.3.1") and missing minor or patch
  # numbers, which count as 0 ("2.3" is 2.3.0). Keep these rules in sync with
  # every other language's SemVer expression.
  class SemVer
    include ::Comparable

    NUMERIC = /0|[1-9]\d*/
    PRERELEASE_IDENTIFIER = /0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*/
    BUILD_IDENTIFIER = /[0-9a-zA-Z-]+/
    PATTERN = /
      \A[vV]?
      (?<major>#{NUMERIC})
      (?:\.(?<minor>#{NUMERIC}))?
      (?:\.(?<patch>#{NUMERIC}))?
      (?:-(?<prerelease>#{PRERELEASE_IDENTIFIER}(?:\.#{PRERELEASE_IDENTIFIER})*))?
      (?:\+(?<build>#{BUILD_IDENTIFIER}(?:\.#{BUILD_IDENTIFIER})*))?
      \z
    /x
    EMPTY = [].freeze

    # Returns a SemVer, or nil when the string isn't a version.
    def self.parse(string)
      match = PATTERN.match(string)
      return unless match

      prerelease = match[:prerelease]&.split(".")&.map do |identifier|
        identifier.match?(/\A\d+\z/) ? identifier.to_i : identifier
      end

      new(
        major: match[:major].to_i,
        minor: match[:minor].to_i,
        patch: match[:patch].to_i,
        prerelease: prerelease || EMPTY,
        build: match[:build]&.split(".") || EMPTY
      )
    end

    attr_reader :major, :minor, :patch, :prerelease, :build

    def initialize(major:, minor:, patch:, prerelease:, build:)
      @major = major
      @minor = minor
      @patch = patch
      @prerelease = prerelease.freeze
      @build = build.freeze
      @precedence = [
        major, minor, patch,
        # A version without a prerelease outranks one with it.
        prerelease.empty? ? 1 : 0,
        # Numeric identifiers rank below alphanumeric ones. Array comparison
        # handles the rest: left to right, and a longer list wins a tie.
        prerelease.map { |id| id.is_a?(Integer) ? [0, id] : [1, id] },
      ].freeze
      freeze
    end

    # SemVer 2.0.0 precedence. Build metadata is ignored, so 1.0.0+a and
    # 1.0.0+b are equal. Returns nil for anything that isn't a SemVer, which
    # makes <, >, etc. raise ArgumentError and the comparison expressions
    # return false.
    def <=>(other)
      return unless other.is_a?(SemVer)

      precedence <=> other.precedence
    end

    def to_s
      string = "#{major}.#{minor}.#{patch}"
      string += "-#{prerelease.join(".")}" if prerelease.any?
      string += "+#{build.join(".")}" if build.any?
      string
    end

    protected

    attr_reader :precedence
  end
end
