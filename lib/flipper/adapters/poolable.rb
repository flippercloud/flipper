# frozen_string_literal: true

module Flipper
  module Adapters
    module Poolable
      def initialize(client_or_pool = nil, key_prefix: nil)
        @pool = nil
        @client = nil
        if client_or_pool.respond_to?(:with)
          @pool = client_or_pool
        else
          @client = client_or_pool
        end
        @key_prefix = key_prefix
      end

      def self.included(klass)
        klass.superclass.instance_methods(false).each do |method|
          klass.define_method method do |*args|
            return super(*args) unless @client.nil?

            @pool.with do |client|
              @client = client
              super(*args)
            ensure
              @client = nil
            end
          end
        end
      end
    end
  end
end
