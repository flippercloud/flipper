require 'bundler/setup'
require 'logger'

require 'flipper/adapters/mongo'
Mongo::Logger.logger.level = Logger::INFO
collection = Mongo::Client.new(["127.0.0.1:#{ENV["MONGODB_PORT"] || 27017}"], :database => 'testing')['flipper']
adapter = Flipper::Adapters::Mongo.new(collection)
flipper = Flipper.new(adapter)

flipper[:stats].enable

if flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end

flipper[:stats].disable

if flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end
