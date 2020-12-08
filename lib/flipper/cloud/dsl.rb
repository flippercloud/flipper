require 'forwardable'

module Flipper
  module Cloud
    class DSL < SimpleDelegator
      attr_reader :cloud_configuration

      def initialize(cloud_configuration)
        @cloud_configuration = cloud_configuration
        super Flipper.new(@cloud_configuration.adapter, instrumenter: @cloud_configuration.instrumenter)
      end
    end
  end
end
