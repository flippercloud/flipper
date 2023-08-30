module Flipper
  module Model
    module ActiveRecord
      include Flipper::Identifier

      # Properties used to evaluate expressions
      def flipper_properties
        {"type" => self.class.name}.merge(attributes)
      end

      # Check if a feature is enabled for this record or any associated actors
      # returned by `#flipper_actors`
      def enabled?(feature_name)
        Flipper.enabled?(feature_name, *flipper_actors)
      end

      # Returns the set of actors associated with this record. Override to
      # return any other records that should be considered actors.
      #
      #   class User < ApplicationRecord
      #     # …
      #     def flipper_actors
      #       [self, company]
      #     end
      #   end
      def flipper_actors
        [self]
      end
    end
  end
end
