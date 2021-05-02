# Flipper Rollout

A [Rollout](https://github.com/fetlife/rollout) adapter for [importing](https://github.com/jnunemaker/flipper/blob/master/docs/Adapters.md#user-content-swapping-adapters
) Rollout data into [Flipper](https://github.com/jnunemaker/flipper).

requires:
  * Rollout ~> 2.0
  * Flipper >= 11.0

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-rollout'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper-redis

## Usage

```ruby
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

# import rollout into redis flipper
Flipper.import(rollout_flipper)
```

That was easy.

### Groups
If you're using [Rollout groups](https://github.com/fetlife/rollout#user-content-groups) you'll need to register them as [Flipper groups](https://github.com/jnunemaker/flipper/blob/master/docs/Gates.md#user-content-2-group):

*Rollout*
```ruby
$rollout.define_group(:caretakers) do |user|
  user.caretaker?
end
```

*Flipper*
```ruby
Flipper.register(:caretakers) do |user|
  user.caretaker?
end
```

### flipper_id

Rollout expects users to respond to *id* (or method specified in [Rollout#initialize](https://github.com/fetlife/rollout/blob/master/lib/rollout.rb#L135) opts) and stores this value in Redis when a feature is activated for a user.  You'll want to make sure that your Flipper actor's [flipper_id](https://github.com/jnunemaker/flipper/blob/master/docs/Gates.md#user-content-3-individual-actor) matches this logic.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
