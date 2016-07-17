require 'test_helper'
require 'flipper/test/v2_shared_adapter_test'
require 'flipper/adapters/v2/memory'

class V2MemoryTest < MiniTest::Test
  prepend Flipper::Test::V2SharedAdapterTests

  def setup
    @adapter = Flipper::Adapters::V2::Memory.new
  end
end
