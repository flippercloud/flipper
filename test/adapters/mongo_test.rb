require 'test_helper'
require 'flipper/adapters/mongo'

class MongoTest < MiniTest::Test
  prepend SharedAdapterTests

  def setup
    host = '127.0.0.1'
    port = '27017'
    collection = Mongo::Client.new(["#{host}:#{port}"], server_selection_timeout: 1, database: 'testing')['testing']
    collection.drop
    collection.create
    @adapter = Flipper::Adapters::Mongo.new(collection)
  end
end
