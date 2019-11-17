module Flipper
  module Adapters
    class ActiveRecord
      # Private: Do not use outside of this adapter.
      class Feature < ::ActiveRecord::Base
        self.table_name = [
          ::ActiveRecord::Base.table_name_prefix,
          "flipper_features",
          ::ActiveRecord::Base.table_name_suffix,
        ].join
      end

      # Private: Do not use outside of this adapter.
      class Gate < ::ActiveRecord::Base
        self.table_name = [
          ::ActiveRecord::Base.table_name_prefix,
          "flipper_gates",
          ::ActiveRecord::Base.table_name_suffix,
        ].join
      end
    end
  end
end
