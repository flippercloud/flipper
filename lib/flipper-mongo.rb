require 'flipper/adapters/mongo'

Flipper.configure do |config|
  config.adapter do
    url = ENV["FLIPPER_MONGO_URL"] || ENV["MONGO_URL"]
    collection = ENV["FLIPPER_MONGO_COLLECTION"] || "flipper"

    unless url
      raise ArgumentError, "The MONGO_URL environment variable must be set. For example: mongodb://127.0.0.1:27017/flipper"
    end

    Flipper::Adapters::Mongo.new(Mongo::Client.new(url)[collection])
  end
end
