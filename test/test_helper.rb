require 'flipper'
require 'minitest/autorun'
require 'minitest/unit'
Dir["./lib/flipper/test/*.rb"].each { |f| require(f) }
