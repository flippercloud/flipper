$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rubygems'
require 'bundler'
Bundler.setup(:default)
require 'rails'
require 'rails/test_help'

ActiveSupport::TestCase.test_order = :random
