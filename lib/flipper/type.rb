module Flipper
  # Internal: Root class for all flipper types. You should never need to use this.
  class Type
    def value
      raise 'Not implemented'
    end
  end
end

require 'flipper/types/actor'
require 'flipper/types/boolean'
require 'flipper/types/group'
require 'flipper/types/percentage'
require 'flipper/types/percentage_of_actors'
require 'flipper/types/percentage_of_random'
