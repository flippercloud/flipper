# Simple class for turning a flipper_id into an actor that can be based
# to Flipper::Feature#enabled?.
module Flipper
  class Actor
    attr_reader :flipper_id, :flipper_properties

    def initialize(flipper_id, flipper_properties = {})
      @flipper_id = flipper_id
      @flipper_properties = flipper_properties
    end

    def eql?(other)
      self.class.eql?(other.class) &&
        @flipper_id == other.flipper_id &&
        @flipper_properties == other.flipper_properties
    end
    alias_method :==, :eql?

    def hash
      flipper_id.hash
    end
  end
end
