require 'test_helper'
require 'flipper/adapters/mongo'

class MongoTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    host = '127.0.0.1'
    port = '27017'
    collection = Mongo::Client.new(
      ["#{host}:#{port}"],
      server_selection_timeout: 1,
      database: 'testing',
      logger: Logger.new("/dev/null")
    )['testing']
    begin
      collection.drop
      collection.create
    rescue Mongo::Error::OperationFailure
    end
    @adapter = Flipper::Adapters::Mongo.new(collection)
  end
end
