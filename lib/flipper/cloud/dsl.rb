require 'forwardable'

module Flipper
  module Cloud
    class DSL < SimpleDelegator
      def initialize(configuration)
        @configuration = configuration
        super Flipper.new(@configuration.adapter, instrumenter: @configuration.instrumenter)
      end
    end
  end
end
