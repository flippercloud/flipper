require 'test_helper'
require 'flipper/test/shared_adapter_test'
require 'flipper/adapters/mongo'

class MongoTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    DataStores.reset_mongo
    @adapter = Flipper::Adapters::Mongo.new(DataStores.mongo)
  end
end
