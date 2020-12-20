require 'forwardable'

module Flipper
  module Cloud
    class DSL < SimpleDelegator
      attr_reader :cloud_configuration

      def initialize(cloud_configuration)
        @cloud_configuration = cloud_configuration
        super Flipper.new(@cloud_configuration.adapter, instrumenter: @cloud_configuration.instrumenter)
      end

      def sync
        @cloud_configuration.sync
      end

      def sync_secret
        @cloud_configuration.sync_secret
      end

      def inspect
        inspect_id = ::Kernel::format "%x", (object_id * 2)
        %(#<#{self.class}:0x#{inspect_id} @cloud_configuration=#{cloud_configuration.inspect}, flipper=#{__getobj__.inspect}>)
      end
    end
  end
end
