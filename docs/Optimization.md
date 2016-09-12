# Optimization

## Memoizing Middleware

One optimization that flipper provides is a memoizing middleware. The memoizing middleware ensures that you only make one adapter call per feature per request.

This means if you check the same feature over and over, it will only make one Mongo, Redis, or whatever call per feature for the length of the request.

You can use the middleware from a Rails initializer like so:

```ruby
# create flipper dsl instance, see above Usage for more details
flipper = Flipper.new(...)

require 'flipper/middleware/memoizer'
config.middleware.use Flipper::Middleware::Memoizer, flipper
```

If you set your flipper instance up in an initializer, you can pass a block to the middleware and it will lazily load the instance the first time the middleware is invoked.

```ruby
# config/initializers/flipper.rb
module MyRailsApp
  def self.flipper
    @flipper ||= Flipper.new(...)
  end
end

# config/application.rb
config.middleware.use Flipper::Middleware::Memoizer, lambda {
  MyRailsApp.flipper
}
```

**Note**: Be sure that the middleware is high enough up in your stack that all feature checks are wrapped.

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
