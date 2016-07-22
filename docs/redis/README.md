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

You can read more about [adapter versioning](../Adapters.md#versioning) here if you are confused. The tl;dr is use the highest version number as that is the latest and greatest.

### V2

```ruby
require 'flipper/adapters/v2/redis'
client = Redis.new
adapter = Flipper::Adapters::V2::Redis.new(client)
flipper = Flipper.new(adapter)
# profit...
```

### V1

```ruby
require 'flipper/adapters/redis'
client = Redis.new
adapter = Flipper::Adapters::Redis.new(client)
flipper = Flipper.new(adapter)
# profit...
```

## Internals

You can learn more about the internals of the adapter by [checking out the example](../../examples/redis/internals.rb).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
