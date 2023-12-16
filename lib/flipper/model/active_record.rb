module Flipper
  module Model
    module ActiveRecord
      # The id of the record when used as an actor.
      #
      #   class User < ActiveRecord::Base
      #   end
      #
      #   user = User.first
      #   Flipper.enable :some_feature, user
      #   Flipper.enabled? :some_feature, user #=> true
      #
      def flipper_id
        "#{self.class.base_class.name};#{id}"
      end

      # Properties used to evaluate expressions
      def flipper_properties
        {"type" => self.class.name}.merge(attributes)
      end
    end
  end
end
