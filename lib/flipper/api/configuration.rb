module Flipper
  module Api
    class Configuration
      # Public: Should all feature gate data be returned with features?
      # Defaults to true.
      # If false, features returned by the API only contain the key and state.
      attr_accessor :include_feature_gate_data

      def initialize
        @include_feature_gate_data = true
      end
    end
  end
end
