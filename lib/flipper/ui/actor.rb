module Flipper
  module UI
    # Internal: Shim for turning a string flipper id into something that responds to
    # flipper_id for Flipper::Types::Actor.
    class Actor
      attr_reader :flipper_id

      def initialize(flipper_id)
        @flipper_id = flipper_id
      end
    end
  end
end
