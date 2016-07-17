require 'test_helper'
require 'flipper/test/v2_shared_adapter_test'
require 'flipper/adapters/v2/memory'
require 'flipper/adapters/v2/dalli'

class V2DalliTest < MiniTest::Test
  prepend Flipper::Test::V2SharedAdapterTests

  def setup
    @cache = Dalli::Client.new('localhost:11211')
    @cache.flush
    memory_adapter = Flipper::Adapters::V2::Memory.new
    @adapter = Flipper::Adapters::V2::Dalli.new(memory_adapter, @cache)
  end

  def teardown
    @cache.flush
  end
end
