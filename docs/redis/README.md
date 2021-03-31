# Flipper Redis

A [Redis](https://github.com/redis/redis-rb) adapter for [Flipper](https://github.com/jnunemaker/flipper).

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-redis'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper-redis

## Usage

In most cases, all you need to do is require the adapter. It will connect to the Redis instance specified in the `REDIS_URL` or `FLIPPER_REDIS_URL` environment vairable, or localhost by default.

```ruby
require 'flipper-redis'
```

**If you need to customize the adapter**, you can add this to an initializer:

```ruby
Flipper.configure do |config|
  config.default do
    client = Redis.new(url: ENV["FLIPPER_REDIS_URL"] || ENV["REDIS_URL"])
    Flipper.new(Flipper::Adapters::Redis.new(client))
  end
end
```

## Internals

Each feature is stored in a redis hash, which means getting a feature is single query.

```ruby
require 'flipper/adapters/redis'

client = Redis.new
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
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
