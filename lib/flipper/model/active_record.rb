module Flipper
  module Model
    module ActiveRecord
      include Flipper::Identifier

      # Properties used to evaluate expressions
      def flipper_properties
        {"type" => self.class.name}.merge(attributes)
      end
    end
  end
end
