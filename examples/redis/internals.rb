require 'bundler/setup'
require 'pp'
require 'logger'

require 'flipper/adapters/redis'

options = {}
if ENV['REDIS_URL']
  options[:url] = ENV['REDIS_URL']
end
client = Redis.new(options)
adapter = Flipper::Adapters::Redis.new(client)
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

print 'all keys: '
pp client.keys
# all keys: ["stats", "flipper_features", "search"]
puts

print "known flipper features: "
pp client.smembers("flipper_features")
# known flipper features: ["stats", "search"]
puts

puts 'stats keys'
pp client.hgetall('stats')
# stats keys
# {"boolean"=>"true",
#  "groups/admins"=>"1",
#  "actors/25"=>"1",
#  "percentage_of_time"=>"15",
#  "percentage_of_actors"=>"45",
#  "groups/early_access"=>"1",
#  "actors/90"=>"1",
#  "actors/180"=>"1"}
puts

puts 'search keys'
pp client.hgetall('search')
# search keys
# {"boolean"=>"true"}
puts

puts 'flipper get of feature'
pp adapter.get(flipper[:stats])
# flipper get of feature
# {:boolean=>"true",
#  :groups=>#<Set: {"admins", "early_access"}>,
#  :actors=>#<Set: {"25", "90", "180"}>,
#  :percentage_of_actors=>"45",
#  :percentage_of_time=>"15"}
