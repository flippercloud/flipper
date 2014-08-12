require 'set'

module Flipper
  class Features < Set
    attr_reader :adapter

    def initialize(features, adapter)
      super(features)
      @adapter = adapter
    end

    # Public: Declare the feature names you expect to flip
    #
    # names - 0..n names of features
    #
    # Returns the names you tried to add
    def declare(*names)
      names.each do |name|
        adapter.add(::Flipper::Feature.new(name, adapter))
        self << Flipper::Feature.new(name, adapter)
      end
      self
    end
  end
end
