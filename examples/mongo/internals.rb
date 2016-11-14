require 'pp'
require 'pathname'
require 'logger'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper/adapters/v2/mongo'
Mongo::Logger.logger.level = Logger::INFO
collection = Mongo::Client.new(["127.0.0.1:#{ENV["BOXEN_MONGODB_PORT"] || 27017}"], :database => 'testing')['flipper']
collection.delete_many
adapter = Flipper::Adapters::V2::Mongo.new(collection)
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
# [{"_id"=>"features",
#   "value"=>
#    "\u0004\bo:\bSet\u0006:\n@hash{\aI\"\nstats\u0006:\u0006EFTI\"\vsearch\u0006;\aFT"},
#  {"_id"=>"feature/stats",
#   "value"=>
#    "\u0004\b{\n:\fbooleanT:\vgroupso:\bSet\u0006:\n@hash{\a:\vadminsT:\u0011early_accessT:\vactorso;\a\u0006;\b{\bI\"\a25\u0006:\u0006ETTI\"\a90\u0006;\fTTI\"\b180\u0006;\fTT:\u0019percentage_of_actorsi2:\u0017percentage_of_timei\u0014"},
#  {"_id"=>"feature/search",
#   "value"=>
#    "\u0004\b{\n:\fbooleanT:\vgroupso:\bSet\u0006:\n@hash{\u0000:\vactorso;\a\u0006;\b{\u0000:\u0019percentage_of_actors0:\u0017percentage_of_time0"}]
puts

puts 'flipper get of feature'
pp JSON.parse(adapter.get("feature/#{flipper[:stats].key}"))
# flipper get of feature
# {:boolean=>true,
#  :groups=>#<Set: {:admins, :early_access}>,
#  :actors=>#<Set: {"25", "90", "180"}>,
#  :percentage_of_actors=>45,
#  :percentage_of_time=>15}
