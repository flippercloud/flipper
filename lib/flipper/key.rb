module Flipper
  # Private: Used internally in flipper to create key to be used for feature in
  # the adapter. You should never need to use this.
  class Key
    # Private
    Separator = '/'

    # Private
    attr_reader :feature_name

    # Private
    attr_reader :gate_key

    # Internal
    def initialize(feature_name, gate_key)
      @feature_name, @gate_key = feature_name, gate_key
    end

    # Private
    def separator
      Separator.dup
    end

    # Private
    def to_s
      "#{feature_name}#{separator}#{gate_key}"
    end

    # Internal: Pretty string version for debugging.
    def inspect
      attributes = [
        "feature_name=#{feature_name.inspect}",
        "gate_key=#{gate_key.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end
  end
end
