require 'test_helper'
require 'flipper/adapters/v2/memory'

class MemoryTest < MiniTest::Test
  prepend Flipper::Test::V2SharedAdapterTests

  def setup
    @adapter = Flipper::Adapters::V2::Memory.new
  end
end
