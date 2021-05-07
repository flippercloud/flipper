# Flipper ActiveSupportCacheStore

An [ActiveSupportCacheStore](http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html) adapter for [Flipper](https://github.com/jnunemaker/flipper).

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-active_support_cache_store'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper-active_support_cache_store

## Usage

```ruby
require 'active_support/cache'
require 'flipper/adapters/active_support_cache_store'

Flipper.configure do |config|
  config.adapter do
    Flipper::Adapters::ActiveSupportCacheStore.new(
      Flipper::Adapters::Memory.new,
      ActiveSupport::Cache::MemoryStore.new, # Or Rails.cache
      expires_in: 5.minutes
    )
  end
end
```

Setting `expires_in` is optional and will set an expiration time on Flipper cache keys.  If specified, all flipper keys will use this `expires_in` over the `expires_in` passed to your ActiveSupport cache constructor.

## Internals

Each feature is stored in the underlying cache store.

This is an example using `ActiveSupport::Cache::MemoryStore` with the [Flipper memory adapter](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/memory.rb).

Each key is namespaced under `flipper/v1/feature/`

```ruby
require 'active_support/cache'
require 'flipper/adapters/active_support_cache_store'

memory_adapter = Flipper::Adapters::Memory.new
cache = ActiveSupport::Cache::MemoryStore.new
adapter = Flipper::Adapters::ActiveSupportCacheStore.new(memory_adapter, cache)
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

# reading all feature keys
pp cache.read("flipper/v1/features")
#<Set: {"stats", "search"}>

# reading a single feature
pp cache.read("flipper/v1/feature/stats")
{
  :boolean=>"true",
  :groups=>#<Set: {"admins", "early_access"}>,
  :actors=>#<Set: {"25", "90", "180"}>,
  :percentage_of_actors=>"45",
  :percentage_of_time=>"15"
}

# flipper get of feature
pp adapter.get(flipper[:stats])
{
  :boolean=>"true",
  :groups=>#<Set: {"admins", "early_access"}>,
  :actors=>#<Set: {"25", "90", "180"}>,
  :percentage_of_actors=>"45",
  :percentage_of_time=>"15"
}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
