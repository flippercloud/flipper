require 'flipper/adapters/active_record/model'

module Flipper
  module Adapters
    class ActiveRecord
      # Private: Do not use outside of this adapter.
      class SyncState < Model
        self.table_name = [
          Model.table_name_prefix,
          "flipper_sync_states",
          Model.table_name_suffix,
        ].join

        validates :key, presence: true
      end
    end
  end
end
