require 'test_helper'
require 'flipper/adapters/dalli'

class DalliTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    url = ENV.fetch('MEMCACHED_URL', 'localhost:11211')
    @cache = Dalli::Client.new(url)
    @cache.flush
    memory_adapter = Flipper::Adapters::Memory.new
    @adapter = Flipper::Adapters::Dalli.new(memory_adapter, @cache)
  end

  def teardown
    @cache.flush
  end
end
