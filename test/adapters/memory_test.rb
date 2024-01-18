require 'test_helper'

class MemoryTest < TestCase
  prepend Flipper::Test::SharedAdapterTests

  def setup
    @adapter = Flipper::Adapters::Memory.new
  end
end
