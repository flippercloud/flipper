require 'test_helper'
require 'flipper/test/shared_adapter_test'

class MemoryTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    @adapter = Flipper::Adapters::Memory.new
  end
end
