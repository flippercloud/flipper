require 'bundler/setup'
require 'flipper'
require 'flipper/test/shared_adapter_test'

require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/hooks'

if ENV["FORK"] == "each"
  # Each `def test_` in each *_test.rb file will be run in a separate process.
  require "minitest/fork_executor"
  Minitest.parallel_executor = Minitest::ForkExecutor.new
else
  # Each *_test.rb file will be run in a separate process.
  require "minitest/parallel_fork"
end

class TestCase < Minitest::Test
  include Minitest::Hooks
end
