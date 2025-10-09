require 'flipper/adapters/active_record/model'

module Flipper
  module Adapters
    class ActiveRecord
      # Private: Do not use outside of this adapter.
      class Feature < Model
        self.table_name = [
          Model.table_name_prefix,
          "flipper_features",
          Model.table_name_suffix,
        ].join

        has_many :gates, foreign_key: "feature_key", primary_key: "key"

        validates :key, presence: true
      end
    end
  end
end
