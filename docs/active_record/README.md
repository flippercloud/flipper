# Flipper ActiveRecord

An ActiveRecord adapter for [Flipper](https://github.com/jnunemaker/flipper).

Supported Active Record versions:

* 5.0.x
* 6.0.x

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-active_record'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper-active_record

## Usage

For your convenience a migration generator is provided to create the necessary migrations for using the active record adapter. By default this generates a migration that will create two database tables - `flipper_features` and `flipper_gates`.

    $ rails g flipper:active_record

Note that the active record adapter requires the database tables to be created in order to work; failure to run the migration first will cause an exception to be raised when attempting to initialize the active record adapter.

Flipper will be configured to use the ActiveRecord adapter when `flipper-active_record` is loaded. But **if you need to customize the adapter**, you can add this to an initializer:

```ruby
require 'flipper/adapters/active_record'
Flipper.configure do |config|
  config.adapter { Flipper::Adapters::ActiveRecord.new }
end
```

## Internals

Each feature is stored as a row in a features table. Each gate is stored as a row in a gates table, related to the feature by the feature's key.

```ruby
# Register a few groups.
Flipper.register(:admins) { |thing| thing.admin? }
Flipper.register(:early_access) { |thing| thing.early_access? }

# Create a user class that has flipper_id instance method.
User = Struct.new(:flipper_id)

Flipper.enable :stats
Flipper.enable_group :stats, :admins
Flipper.enable_group :stats, :early_access
Flipper.enable_actor :stats, User.new('25')
Flipper.enable_actor :stats, User.new('90')
Flipper.enable_actor :stats, User.new('180')
Flipper.enable_percentage_of_time :stats, 15
Flipper.enable_percentage_of_actors :stats, 45

Flipper.enable :search

puts 'all rows in features table'
pp Flipper::Adapters::ActiveRecord::Feature.all
# [#<Flipper::Adapters::ActiveRecord::Feature:0x007fd259b47110
#   id: 1,
#   key: "stats",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>,
#  #<Flipper::Adapters::ActiveRecord::Feature:0x007fd259b46cd8
#   id: 2,
#   key: "search",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>]
puts

puts 'all rows in gates table'
pp Flipper::Adapters::ActiveRecord::Gate.all
# [#<Flipper::Adapters::ActiveRecord::Gate:0x007fd259b0f0f8
#   id: 1,
#   feature_key: "stats",
#   key: "boolean",
#   value: "true",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>,
#  #<Flipper::Adapters::ActiveRecord::Gate:0x007fd259b0ebd0
#   id: 2,
#   feature_key: "stats",
#   key: "groups",
#   value: "admins",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>,
#  #<Flipper::Adapters::ActiveRecord::Gate:0x007fd259b0e748
#   id: 3,
#   feature_key: "stats",
#   key: "groups",
#   value: "early_access",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>,
#  #<Flipper::Adapters::ActiveRecord::Gate:0x007fd259b0e568
#   id: 4,
#   feature_key: "stats",
#   key: "actors",
#   value: "25",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>,
#  #<Flipper::Adapters::ActiveRecord::Gate:0x007fd259b0e0b8
#   id: 5,
#   feature_key: "stats",
#   key: "actors",
#   value: "90",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>,
#  #<Flipper::Adapters::ActiveRecord::Gate:0x007fd259b0da50
#   id: 6,
#   feature_key: "stats",
#   key: "actors",
#   value: "180",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>,
#  #<Flipper::Adapters::ActiveRecord::Gate:0x007fd259b0d3c0
#   id: 7,
#   feature_key: "stats",
#   key: "percentage_of_time",
#   value: "15",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>,
#  #<Flipper::Adapters::ActiveRecord::Gate:0x007fd259b0cdf8
#   id: 8,
#   feature_key: "stats",
#   key: "percentage_of_actors",
#   value: "45",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>,
#  #<Flipper::Adapters::ActiveRecord::Gate:0x007fd259b0cbf0
#   id: 9,
#   feature_key: "search",
#   key: "boolean",
#   value: "true",
#   created_at: 2015-12-21 16:26:29 UTC,
#   updated_at: 2015-12-21 16:26:29 UTC>]
puts

puts 'flipper get of feature'
pp adapter.get(flipper[:stats])
# flipper get of feature
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
