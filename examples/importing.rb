require File.expand_path('../example_setup', __FILE__)

require 'flipper'
require 'flipper/adapters/redis'
require 'flipper/adapters/active_record'

# Active Record boiler plate, feel free to ignore.
ActiveRecord::Base.establish_connection({
  adapter: 'sqlite3',
  database: ':memory:',
})
require 'generators/flipper/templates/migration'
CreateFlipperTables.up


# Say you are using redis...
redis_adapter = Flipper::Adapters::Redis.new(Redis.new)
redis_flipper = Flipper.new(redis_adapter)

# And redis has some stuff enabled...
redis_flipper.enable(:search)
redis_flipper.enable_percentage_of_time(:verbose_logging, 5)
redis_flipper.enable_percentage_of_actors(:new_feature, 5)
redis_flipper.enable_actor(:issues, Flipper::Actor.new('1'))
redis_flipper.enable_actor(:issues, Flipper::Actor.new('2'))
redis_flipper.enable_group(:request_tracing, :staff)

# And would like to switch to active record...
ar_adapter = Flipper::Adapters::ActiveRecord.new
ar_flipper = Flipper.new(ar_adapter)

# Note: This wipes active record clean and copies features/gates from redis.
ar_flipper.import(redis_flipper)

# AR is now identical to Redis.
ar_flipper.features.each do |feature|
  pp feature: feature.key, values: feature.gate_values
end
