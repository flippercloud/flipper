require 'bundler/setup'
require 'pp'
require 'logger'

require 'flipper/adapters/mongo'
Mongo::Logger.logger.level = Logger::INFO
collection = Mongo::Client.new(["127.0.0.1:#{ENV["MONGODB_PORT"] || 27017}"], :database => 'testing')['flipper']
adapter = Flipper::Adapters::Mongo.new(collection)
flipper = Flipper.new(adapter)

# Register a few groups.
Flipper.register(:admins) { |thing| thing.admin? }
Flipper.register(:early_access) { |thing| thing.early_access? }

# Create a user class that has flipper_id instance method.
User = Struct.new(:flipper_id)

flipper[:stats].enable
flipper[:stats].enable_group :admins
flipper[:stats].enable_group :early_access
flipper[:stats].enable_actor User.new('25')
flipper[:stats].enable_actor User.new('90')
flipper[:stats].enable_actor User.new('180')
flipper[:stats].enable_percentage_of_time 15
flipper[:stats].enable_percentage_of_actors 45

flipper[:search].enable

puts 'all docs in collection'
pp collection.find.to_a
# all docs in collection
# [{"_id"=>"stats",
#   "actors"=>["25", "90", "180"],
#   "boolean"=>"true",
#   "groups"=>["admins", "early_access"],
#   "percentage_of_actors"=>"45",
#   "percentage_of_time"=>"15"},
#  {"_id"=>"flipper_features", "features"=>["stats", "search"]},
#  {"_id"=>"search", "boolean"=>"true"}]
puts

puts 'flipper get of feature'
pp adapter.get(flipper[:stats])
# flipper get of feature
# {:boolean=>"true",
#  :groups=>#<Set: {"admins", "early_access"}>,
#  :actors=>#<Set: {"25", "90", "180"}>,
#  :percentage_of_actors=>"45",
#  :percentage_of_time=>"15"}
