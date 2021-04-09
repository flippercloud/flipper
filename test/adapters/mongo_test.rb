require 'test_helper'
require 'flipper/adapters/mongo'

class MongoTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    host = ENV.fetch('MONGODB_HOST', '127.0.0.1')
    port = '27017'
    logger = Logger.new('/dev/null')
    client = Mongo::Client.new(["#{host}:#{port}"],
                               server_selection_timeout: 0.01,
                               database: 'testing',
                               logger: logger)
    collection = client['testing']
    begin
      collection.drop
      collection.create
    rescue Mongo::Error::NoServerAvailable
      skip "Mongo not available"
    rescue Mongo::Error::OperationFailure
    end
    @adapter = Flipper::Adapters::Mongo.new(collection)
  end
end
