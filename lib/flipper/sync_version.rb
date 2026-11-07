module Flipper
  # Internal: The version of a set of synced flags. Flipper Cloud sends it in
  # the flipper-sync-version header and it goes up on every flag change. Syncs
  # use it so an older response never replaces newer flags.
  #
  # Versions only compare within one scope (one remote, such as one Cloud
  # environment). A local adapter pointed at a different remote starts over
  # instead of waiting for the old remote's numbers.
  class SyncVersion
    HEADER = "flipper-sync-version".freeze

    attr_reader :scope, :number

    # Public: Builds a version from a header value. Returns nil when the value
    # is missing or not an integer.
    def self.from_header(scope, value)
      number = Integer(value.to_s, 10) rescue nil
      new(scope, number) if number
    end

    # Public: Builds a version from a String made by #to_s. Returns nil when
    # the value is missing or malformed.
    def self.parse(value)
      scope, _, number = value.to_s.rpartition(":")
      from_header(scope, number) unless scope.empty?
    end

    def initialize(scope, number)
      @scope = scope.to_s
      @number = number
    end

    # Public: Is this version older than other? Versions from different scopes
    # are never older than each other.
    def older_than?(other)
      return false unless other
      scope == other.scope && number < other.number
    end

    def ==(other)
      other.is_a?(SyncVersion) && scope == other.scope && number == other.number
    end
    alias eql? ==

    def hash
      [scope, number].hash
    end

    def to_s
      "#{scope}:#{number}"
    end

    def inspect
      "#<#{self.class.name} #{self}>"
    end
  end
end
