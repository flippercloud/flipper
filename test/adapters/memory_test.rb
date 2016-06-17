require 'test_helper'
require 'flipper/adapters/memory'

class MemoryTest < MiniTest::Test
  prepend SharedAdapterTests

  def setup
    @adapter = Flipper::Adapters::Memory.new
  end
end
