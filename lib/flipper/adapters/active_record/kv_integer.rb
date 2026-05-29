require 'flipper/adapters/active_record/model'

module Flipper
  module Adapters
    class ActiveRecord
      # Private: Do not use outside of this adapter.
      class KvInteger < Model
        self.table_name = [
          Model.table_name_prefix,
          "flipper_kv_integers",
          Model.table_name_suffix,
        ].join

        validates :key, presence: true
      end
    end
  end
end
