require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
require 'rails'
require 'rails/test_help'

begin
  ActiveSupport::TestCase.test_order = :random
rescue NoMethodError
  # no biggie, means we are on older version of AS that doesn't have this option
end
