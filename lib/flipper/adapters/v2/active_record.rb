module Flipper
  module Adapters
    module V2
      class ActiveRecord
        include ::Flipper::Adapter

        # Private: Do not use outside of this adapter.
        class Key < ::ActiveRecord::Base
          self.table_name = "flipper_keys"
        end

        attr_reader :name

        def initialize
          @name = :active_record
        end

        def version
          Adapter::V2
        end

        def get(key)
          if row = Key.where(:key => key).limit(1).first
            row.value
          end
        end

        def set(key, value)
          if row = Key.where(:key => key).limit(1).first
            row.value = value.to_s
            row.save!
          else
            Key.create!(:key => key, :value => value.to_s)
          end
        end

        def del(key)
          Key.where(:key => key).delete_all
        end
      end
    end
  end
end
