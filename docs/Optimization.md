# Optimization

## Memoizing Middleware

One optimization that flipper provides is a memoizing middleware. The memoizing middleware ensures that you only make one adapter call per feature per request. This means if you check the same feature over and over, it will only make one Mongo, Redis, or whatever call per feature for the length of the request.

You can use the middleware like so for Rails:

```ruby
# setup default instance (perhaps in config/initializers/flipper.rb)
Flipper.configure do |config|
  config.default do
    Flipper.new(...)
  end
end

# This assumes you setup a default flipper instance using configure.
Rails.configuration.middleware.use Flipper::Middleware::Memoizer
```

**Note**: Be sure that the middleware is high enough up in your stack that all feature checks are wrapped.

**Also Note**: If you haven't setup a default instance, you can pass the instance to `SetupEnv` as `Memoizer` uses whatever is setup in the `env`:

```ruby
Rails.configuration.middleware.use Flipper::Middleware::SetupEnv, -> { Flipper.new(...) }
Rails.configuration.middleware.use Flipper::Middleware::Memoizer
```

### Options

The Memoizer middleware also supports a few options. Use either `preload` or `preload_all`, not both.

* **`:preload`** - An `Array` of feature names (`Symbol`) to preload for every request. Useful if you have features that are used on every endpoint. `preload` uses `Adapter#get_multi` to attempt to load the features in one network call instead of N+1 network calls.
    ```ruby
    Rails.configuration.middleware.use Flipper::Middleware::Memoizer,
      preload: [:stats, :search, :some_feature]
    ```
* **`:preload_all`** - A Boolean value (default: false) of whether or not all features should be preloaded. Using this results in a `preload_all` call with the result of `Adapter#get_all`. Any subsequent feature checks will be memoized and perform no network calls. I wouldn't recommend using this unless you have few features (< 100?) and nearly all of them are used on every request.
    ```ruby
    Rails.configuration.middleware.use Flipper::Middleware::Memoizer,
      preload_all: true
    ```
* **`:unless`** - A block that prevents preloading and memoization if it evaluates to true.
    ```ruby
    # skip preloading and memoizing if path starts with /assets
    Rails.configuration.middleware.use Flipper::Middleware::Memoizer,
      unless: ->(request) { request.path.start_with?("/assets") }
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
