module Flipper
  module Adapters
    class ActiveRecord
      class Model < ::ActiveRecord::Base
        self.abstract_class = true
      end
    end
  end
end
