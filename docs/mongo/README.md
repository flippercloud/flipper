# Flipper Mongo

A [MongoDB](https://github.com/mongodb/mongo-ruby-driver) adapter for [Flipper](https://github.com/jnunemaker/flipper).

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-mongo'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper-mongo

## Usage

In most cases, all you need to do is require the adapter. You must set the `MONGO_URL` or `FLIPPER_MONGO_URL` environment vairable to specify which Mongo database to connect to.

```ruby
require 'flipper-mongo`
```

**If you need to customize the adapter**, you can add this to an initializer:

```ruby
Flipper.configure do |config|
  config.default do
    collection = Mongo::Client.new(ENV["MONGO_URL"])["flipper"]
    Flipper.new(Flipper::Adapters::Mongo.new(collection))
  end
end
```

## Internals

Each feature is stored in a document, which means getting a feature is single query.

```ruby
require 'flipper/adapters/mongo'
collection = Mongo::Client.new(["127.0.0.1:27017"], database: 'testing')['flipper']
adapter = Flipper::Adapters::Mongo.new(collection)
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

puts 'all docs in collection'
pp collection.find.to_a
# all docs in collection
# [{"_id"=>"stats",
#   "actors"=>["25", "90", "180"],
#   "boolean"=>"true",
#   "groups"=>["admins", "early_access"],
#   "percentage_of_actors"=>"45",
#   "percentage_of_time"=>"15"},
#  {"_id"=>"flipper_features", "features"=>["stats", "search"]},
#  {"_id"=>"search", "boolean"=>"true"}]
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
