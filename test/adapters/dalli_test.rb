require 'test_helper'
require 'flipper/test/shared_adapter_test'
require 'flipper/adapters/memory'
require 'flipper/adapters/dalli'

class DalliTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    memory_adapter = Flipper::Adapters::Memory.new
    @adapter = Flipper::Adapters::Dalli.new(memory_adapter, DataStores.dalli)
    DataStores.reset_dalli
  end
end
