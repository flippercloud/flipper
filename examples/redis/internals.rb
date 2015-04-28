require 'pp'
require 'pathname'
require 'logger'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper/adapters/redis'
require 'redis/namespace'

client = Redis.new
namespaced_client = Redis::Namespace.new(:flipper, :redis => client)
adapter = Flipper::Adapters::Redis.new(namespaced_client)
flipper = Flipper.new(adapter)

# Register a few groups.
Flipper.register(:admins) { |thing| thing.admin? }
Flipper.register(:early_access) { |thing| thing.early_access? }

# Create a user class that has flipper_id instance method.
User = Struct.new(:flipper_id)

flipper[:stats].enable
flipper[:stats].enable flipper.group(:admins)
flipper[:stats].enable flipper.group(:early_access)
flipper[:stats].enable User.new('25')
flipper[:stats].enable User.new('90')
flipper[:stats].enable User.new('180')
flipper[:stats].enable flipper.random(15)
flipper[:stats].enable flipper.actors(45)

flipper[:search].enable

print 'all keys: '
pp namespaced_client.keys
# all keys: ["stats", "flipper_features", "search"]
puts

print "known flipper features: "
pp namespaced_client.smembers("flipper_features")
# known flipper features: ["stats", "search"]
puts

puts 'stats keys'
pp namespaced_client.hgetall('stats')
# stats keys
# {"boolean"=>"true",
#  "groups/admins"=>"1",
#  "actors/25"=>"1",
#  "percentage_of_random"=>"15",
#  "percentage_of_actors"=>"45",
#  "groups/early_access"=>"1",
#  "actors/90"=>"1",
#  "actors/180"=>"1"}
puts

puts 'search keys'
pp namespaced_client.hgetall('search')
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
#  :percentage_of_random=>"15"}
