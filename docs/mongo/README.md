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

```ruby
require 'flipper/adapters/mongo'
collection = Mongo::MongoClient.new.db('testing')['flipper']
adapter = Flipper::Adapters::Mongo.new(collection)
flipper = Flipper.new(adapter)
# profit...
```

## Internals

Each feature is stored in a document, which means getting a feature is single query.

```ruby
require 'flipper/adapters/mongo'
collection = Mongo::MongoClient.new.db('testing')['flipper']
adapter = Flipper::Adapters::Mongo.new(collection)
flipper = Flipper.new(adapter)

# Register a few groups.
Flipper.register(:admins) { |thing| thing.admin? }
Flipper.register(:early_access) { |thing| thing.early_access? }

# Create a user class that has flipper_id instance method.
User = Struct.new(:flipper_id)

flipper[:stats].enable
flipper[:stats].enable flipper.group(:admins)
flipper[:stats].enable flipper.group(:early_access)
flipper[:stats].enable User.new('25')
flipper[:stats].enable User.new('90')
flipper[:stats].enable User.new('180')
flipper[:stats].enable flipper.random(15)
flipper[:stats].enable flipper.actors(45)

flipper[:search].enable

puts 'all docs in collection'
pp collection.find.to_a
# all docs in collection
# [{"_id"=>"stats",
#   "actors"=>["25", "90", "180"],
#   "boolean"=>"true",
#   "groups"=>["admins", "early_access"],
#   "percentage_of_actors"=>"45",
#   "percentage_of_random"=>"15"},
#  {"_id"=>"flipper_features", "features"=>["stats", "search"]},
#  {"_id"=>"search", "boolean"=>"true"}]

puts 'flipper get of feature'
pp adapter.get(flipper[:stats])
# flipper get of feature
# {:boolean=>"true",
#  :groups=>#<Set: {"admins", "early_access"}>,
#  :actors=>#<Set: {"25", "90", "180"}>,
#  :percentage_of_actors=>"45",
#  :percentage_of_random=>"15"}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
