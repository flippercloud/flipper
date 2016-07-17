require 'flipper'
require 'redis'

module Flipper
  module Adapters
    module V2
      class Redis
        include ::Flipper::Adapter

        attr_reader :name

        def initialize(client)
          @client = client
          @name = :redis
        end

        def version
          Adapter::V2
        end

        def get(key)
          @client.get(key)
        end

        def set(key, value)
          @client.set(key, value.to_s)
        end

        def del(key)
          @client.del(key)
        end
      end
    end
  end
end
