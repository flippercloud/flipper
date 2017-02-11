require 'flipper'
require 'mongo'

module Flipper
  module Adapters
    module V2
      class Mongo
        include ::Flipper::Adapter

        # Public: The name of the adapter.
        attr_reader :name

        def initialize(collection)
          @collection = collection
          @name = :mongo
        end

        def version
          Adapter::V2
        end

        def get(key)
          criteria = { _id: key.to_s }
          if doc = @collection.find(criteria).limit(1).first
            doc["value"]
          end
        end

        def set(key, value)
          criteria = { _id: key.to_s }
          options = { upsert: true }
          updates = { '$set' => { "value" => value.to_s } }
          @collection.find(criteria).update_one(updates, options)
        end

        def del(key)
          criteria = { _id: key.to_s }
          @collection.find(criteria).delete_one
        end
      end
    end
  end
end
