module Flipper
  module Model
    module Sequel
      include Flipper::Identifier

      # Properties used to evaluate rules
      def flipper_properties
        {"type" => self.class.name}.update(to_hash.transform_keys(&:to_s))
      end
    end
  end
end
