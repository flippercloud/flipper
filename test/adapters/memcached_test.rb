require 'test_helper'
require 'flipper/adapters/memory'
require 'flipper/adapters/memcached'

class MongoTest < MiniTest::Test
  prepend SharedAdapterTests

  def setup
    memory_adapter = Flipper::Adapters::Memory.new
    @adapter = Flipper::Adapters::Memcached.new(memory_adapter)
  end
end
