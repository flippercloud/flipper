# Flipper Moneta

A [Moneta](https://github.com/minad/moneta) adapter for [Flipper](https://github.com/jnunemaker/flipper).

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-moneta'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper-moneta

## Usage

```ruby
require 'flipper/adapters/moneta'
moneta = Moneta.new(:Memory)

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::Moneta.new(moneta) }
end
```

## Internals

Each feature is stored as a key namespaced by `flipper_features`.

```ruby
require 'flipper/adapters/moneta'
moneta = Moneta.new(:Memory)

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::Moneta.new(moneta) }
end

# Register a few groups.
Flipper.register(:admins) { |thing| thing.admin? }
Flipper.register(:early_access) { |thing| thing.early_access? }

# Create a user class that has flipper_id instance method.
User = Struct.new(:flipper_id)

Flipper[:stats].enable
Flipper[:stats].enable_group :admins
Flipper[:stats].enable_group :early_access
Flipper[:stats].enable_actor User.new('25')
Flipper[:stats].enable_actor User.new('90')
Flipper[:stats].enable_actor User.new('180')
Flipper[:stats].enable_percentage_of_time 15
Flipper[:stats].enable_percentage_of_actors 45

pp moneta["flipper_features/stats"]

{:boolean=>"true",
 :groups=>#<Set: {"admins", "early_access"}>,
 :actors=>#<Set: {"25", "90", "180"}>,
 :percentage_of_actors=>"45",
 :percentage_of_time=>"15"}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
