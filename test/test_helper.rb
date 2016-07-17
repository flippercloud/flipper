require 'flipper'
require 'minitest/autorun'
require 'minitest/unit'

FlipperRoot = Pathname(__FILE__).dirname.join('..').expand_path

require 'rubygems'
require 'bundler/setup'
require 'rails'
require 'rails/test_help'

begin
  ActiveSupport::TestCase.test_order = :random
rescue NoMethodError => boom
  # no biggie, means we are on older version of AS that doesn't have this option
end
