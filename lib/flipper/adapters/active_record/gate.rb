require 'flipper/adapters/active_record/model'

module Flipper
  module Adapters
    class ActiveRecord
      # Private: Do not use outside of this adapter.
      class Gate < Model
        self.table_name = [
          Model.table_name_prefix,
          "flipper_gates",
          Model.table_name_suffix,
        ].join

        validates :feature_key, presence: true
        validates :key, presence: true
      end
    end
  end
end
