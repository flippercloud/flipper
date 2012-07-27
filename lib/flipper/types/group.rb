module Flipper
  module Types
    class Group < Type
      def self.all
        @all ||= []
      end

      def self.define(name, &block)
        group = new(name, &block)
        all.push group
        group
      end

      def self.get(name)
        detect { |group| group.name == name }
      end

      class << self
        include Enumerable

        def each
          all.each { |group| yield group }
        end
      end

      attr_reader :name

      def initialize(name, &block)
        @name = name
        @block = block
      end

      def match?(*args)
        @block.call(*args) == true
      end

      def enabled_value
        @name
      end

      alias_method :disabled_value, :enabled_value
    end
  end
end
