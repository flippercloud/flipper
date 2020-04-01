# Flipper ActiveRecord

An ActiveRecord adapter for [Flipper](https://github.com/jnunemaker/flipper).

Supported Active Record versions:

* 4.2.x
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

For your convenience a migration generator is provided to create the necessary migrations for using the active record adapter. By default this generates a migration that will create two database tables - flipper_features and flipper_gates.

    $ rails g flipper:active_record

Once you have created and executed the migration, you can use the active record adapter like so:

```ruby
require 'flipper/adapters/active_record'
adapter = Flipper::Adapters::ActiveRecord.new
flipper = Flipper.new(adapter)
# profit...
```

## Rails Initialization

The current convention in the Ruby-on-Rails community is to instantiate a Flipper object in a Rails initializer, like so:

```ruby
# config/initializers/flipper.rb

require 'flipper/adapters/active_record'

Flipper.configure do |config|
    config.default do
        adapter = Flipper::Adapters::ActiveRecord.new
        Flipper.new(adapter)
    end
    # Setting of flags, etc...
end
```

This is fine, but will cause an issue in places where your new Flipper-related migration has not already run, such as continuous integration pipelines; the initializer will try to instantiate a Flipper object, which will look for the necessary database tables but fail to find them.

One way to avoid this situation is to *only* instantiate our Flipper object after confirming that the necessary database tables have been created:

```ruby
# config/initializers/flipper.rb

require 'flipper/adapters/active_record'

if ActiveRecord::Base.connection.table_exists? :flipper_features
    Flipper.configure do |config|
        config.default do
            adapter = Flipper::Adapters::ActiveRecord.new
            Flipper.new(adapter)
        end
        # Setting of flags, etc...
    end
end
```

## Internals

Each feature is stored as a row in a features table. Each gate is stored as a row in a gates table, related to the feature by the feature's key.

```ruby
require 'flipper/adapters/active_record'
adapter = Flipper::Adapters::ActiveRecord.new
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
