require 'bundler/setup'
require 'pp'
require 'logger'

ENV["FLIPPER_MONGO_URL"] ||= "127.0.0.1:#{ENV["MONGODB_PORT"] || 27017}"
require 'flipper/adapters/mongo'

# Register a few groups.
Flipper.register(:admins) { |thing| thing.admin? }
Flipper.register(:early_access) { |thing| thing.early_access? }

# Create a user class that has flipper_id instance method.
User = Struct.new(:flipper_id)

Flipper[:stats].enable
Flipper[:stats].enable_group :admins
Flipper[:stats].enable_group :early_access
Flipper[:stats].enable_actor User.new('25')
Flipper[:stats].enable_actor User.new('90')
Flipper[:stats].enable_actor User.new('180')
Flipper[:stats].enable_percentage_of_time 15
Flipper[:stats].enable_percentage_of_actors 45

Flipper[:search].enable

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
pp Flipper.adapter.get(Flipper[:stats])
# flipper get of feature
# {:boolean=>"true",
#  :groups=>#<Set: {"admins", "early_access"}>,
#  :actors=>#<Set: {"25", "90", "180"}>,
#  :percentage_of_actors=>"45",
#  :percentage_of_time=>"15"}
