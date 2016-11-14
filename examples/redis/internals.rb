require 'pp'
require 'pathname'
require 'logger'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper/adapters/v2/redis'

client = Redis.new
client.flushdb
adapter = Flipper::Adapters::V2::Redis.new(client)
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
# all keys: ["features", "feature/stats", "feature/search"]
puts

puts 'flipper get of feature'
pp JSON.parse(adapter.get("feature/#{flipper[:stats].key}"))
# flipper get of feature
# {:boolean=>true,
#  :groups=>#<Set: {:admins, :early_access}>,
#  :actors=>#<Set: {"25", "90", "180"}>,
#  :percentage_of_actors=>45,
#  :percentage_of_time=>15}
