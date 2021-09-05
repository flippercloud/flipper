require 'flipper/rules/condition'
require 'flipper/rules/any'
require 'flipper/rules/all'
require 'flipper/rules/property'

module Flipper
  module Rules
    def self.wrap(thing)
      if thing.is_a?(Flipper::Rules::Rule)
        thing
      else
        build(thing)
      end
    end

    def self.build(hash)
      type = const_get(hash.fetch("type"))
      type.build(hash.fetch("value"))
    end
  end
end
