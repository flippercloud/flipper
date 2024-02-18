require "test_helper"
require "flipper/test/shared_adapter_test"
require "flipper/adapters/actor_limit"

class Flipper::Adapters::ActorLimitTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    @memory = Flipper::Adapters::Memory.new
    @adapter = Flipper::Adapters::ActorLimit.new(@memory, 5)
  end

  def test_enable_fails_when_limit_exceeded
    5.times { |i| @feature.enable Flipper::Actor.new("User;#{i}") }

    assert_raises Flipper::Adapters::ActorLimit::LimitExceeded do
      @feature.enable Flipper::Actor.new("User;6")
    end
  end
end
