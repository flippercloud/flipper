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

You can read more about [adapter versioning](../Adapters.md#versioning) here if you are confused. The tl;dr is use the highest version number as that is the latest and greatest.

### V2

```ruby
require 'flipper/adapters/v2/mongo'
collection = Mongo::Client.new(["127.0.0.1:27017"], database: 'testing')['flipper']
adapter = Flipper::Adapters::V2::Mongo.new(collection)
flipper = Flipper.new(adapter)
# profit...
```

### V1

```ruby
require 'flipper/adapters/mongo'
collection = Mongo::Client.new(["127.0.0.1:27017"], database: 'testing')['flipper']
adapter = Flipper::Adapters::Mongo.new(collection)
flipper = Flipper.new(adapter)
# profit...
```

## Internals

You can learn more about the internals of the adapter by [checking out the example](../../examples/mongo/internals.rb).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
