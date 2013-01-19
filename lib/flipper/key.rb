module Flipper
  class Key
    Separator = '/'

    attr_reader :feature_name, :gate_key

    def initialize(feature_name, gate_key)
      @feature_name, @gate_key = feature_name, gate_key
    end

    def separator
      Separator.dup
    end

    def to_s
      "#{feature_name}#{separator}#{gate_key}"
    end

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "feature_name=#{feature_name.inspect}",
        "gate_key=#{gate_key.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end
  end
end
