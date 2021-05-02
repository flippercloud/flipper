# Optimization

## Memoization

By default, Flipper will preload and memoize all features to ensure one adapter call per request. This means no matter how many times you check features, Flipper will only make one network request to Mongo, Redis, or whatever adapter you are using for the length of the request.

### Preloading

By default, Flipper will preload all features before each request. This is recommended if you have a limited number of features (< 100?) and they are used on most requests. If you have a lot of features, but only a few are used on most requests, you may want to customize preloading:

```ruby
# config/initializers/flipper.rb
Flipper.configure do |config|
  # Load specific features that are used on most requests
  config.preload = [:stats, :search, :some_feature]

  # Disable preloading
  config.preload = false
end
```

Features that are not preloaded are still memoized, ensuring one adapter call per feature during a request.

### Skip memoization

Prevent preloading and memoization on specific requests by setting `memoize` to a proc that evaluates to false.

```ruby
# config/initializers/flipper.rb
Flipper.configure do |config|
  config.memoize = ->(request) { !request.path.start_with?("/assets") }
end
```

### Disable memoization

To disable memoization entirely:

```ruby
Flipper.configure do |config|
  config.memoize = false
end
```

### Advanced

Memoization is implemented as a Rack middleware, which can be used manually in any Ruby app:

```ruby
use Flipper::Middleware::Memoizer,
  preload: true,
  unless: ->(request) { request.path.start_with?("/assets") }
```

**Also Note**: If you need to customize the instance of Flipper used by the memoizer, you can pass the instance to `SetupEnv`:

```ruby
use Flipper::Middleware::SetupEnv, -> { Flipper.new(...) }
use Flipper::Middleware::Memoizer
```

## Cache Adapters

Cache adapters allow you to cache adapter calls for longer than a single request and should be used alongside the memoization middleware to add another caching layer.

### Dalli

> Dalli is a high performance pure Ruby client for accessing memcached servers.

https://github.com/petergoldstein/dalli

Example using the Dalli cache adapter with the Memory adapter and a TTL of 600 seconds:

```ruby
dalli_client = Dalli::Client.new('localhost:11211')
memory_adapter = Flipper::Adapters::Memory.new
adapter = Flipper::Adapters::Dalli.new(memory_adapter, dalli_client, 600)
flipper = Flipper.new(adapter)
```
### RedisCache

Applications using [Redis](https://redis.io/) via the [redis-rb](https://github.com/redis/redis-rb) client can take advantage of the RedisCache adapter.

Initialize `RedisCache`  with a flipper [adapter](https://github.com/jnunemaker/flipper/blob/master/docs/Adapters.md), a Redis client instance, and an optional TTL in seconds. TTL defaults to 3600 seconds.

Example using the RedisCache adapter with the Memory adapter and a TTL of 4800 seconds:

```ruby
  require 'flipper/adapters/redis_cache'

  redis = Redis.new(url: ENV['REDIS_URL'])
  memory_adapter = Flipper::Adapters::Memory.new
  adapter = Flipper::Adapters::RedisCache.new(memory_adapter, redis, 4800)
  flipper = Flipper.new(adapter)
```

### ActiveSupportCacheStore

Rails applications can cache Flipper calls in any [ActiveSupport::Cache::Store](http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html) implementation.

Add this line to your application's Gemfile:

    gem 'flipper-active_support_cache_store'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper-active_support_cache_store

Example using the ActiveSupportCacheStore adapter with ActiveSupport's [MemoryStore](http://api.rubyonrails.org/classes/ActiveSupport/Cache/MemoryStore.html), Flipper's [Memory adapter](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/memory.rb), and a TTL of 5 minutes.

```ruby
require 'active_support/cache'
require 'flipper/adapters/active_support_cache_store'

memory_adapter = Flipper::Adapters::Memory.new
cache = ActiveSupport::Cache::MemoryStore.new
adapter = Flipper::Adapters::ActiveSupportCacheStore.new(memory_adapter, cache, expires_in: 5.minutes)
flipper = Flipper.new(adapter)
```

Setting `expires_in` is optional and will set an expiration time on Flipper cache keys.  If specified, all flipper keys will use this `expires_in` over the `expires_in` passed to your ActiveSupport cache constructor.
