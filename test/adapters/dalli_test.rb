require 'test_helper'
require 'flipper/adapters/memory'
require 'flipper/adapters/dalli'

class DalliTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    @cache = Dalli::Client.new('localhost:11211')
    @cache.flush
    memory_adapter = Flipper::Adapters::Memory.new
    @adapter = Flipper::Adapters::Dalli.new(memory_adapter, @cache)
  end

  def teardown
    @cache.flush
  end
end
