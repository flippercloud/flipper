require 'flipper/rules/condition'
require 'flipper/rules/any'
require 'flipper/rules/all'

module Flipper
  module Rules
    def self.build(hash)
      type = const_get(hash.fetch("type"))
      type.build(hash.fetch["value"])
    end
  end
end
