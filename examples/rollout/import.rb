require 'bundler/setup'
require 'redis'
require 'rollout'
require 'flipper'
require 'flipper/adapters/redis'
require 'flipper/adapters/rollout'

# setup redis, rollout and rollout flipper
redis = Redis.new
rollout = Rollout.new(redis)
rollout_adapter = Flipper::Adapters::Rollout.new(rollout)
rollout_flipper = Flipper.new(rollout_adapter)

# setup flipper default instance
Flipper.configure do |config|
  config.adapter { Flipper::Adapters::Redis.new(redis) }
end

# flush redis so we have clean state for script
redis.flushdb

# activate some rollout stuff to show that importing works
rollout.activate(:stats)
rollout.activate_user(:search, Struct.new(:id).new(1))
rollout.activate_group(:admin, :admins)

# import rollout into redis flipper
Flipper.import(rollout_flipper)

# demonstrate that the rollout enablements made it into flipper
p Flipper[:stats].boolean_value # true
p Flipper[:search].actors_value # #<Set: {"1"}>
p Flipper[:admin].groups_value # #<Set: {"admins"}>
