# Flipper ActiveRecord

An ActiveRecord adapter for [Flipper](https://github.com/jnunemaker/flipper).

Supported Active Record versions:

* 3.2.x
* 4.2.x
* 5.0.x

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-active_record'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper-active_record

## Usage

You can read more about [adapter versioning](../Adapters.md#versioning) here if you are confused. The tl;dr is use the highest version number as that is the latest and greatest.

### V2

For your convenience a migration generator is provided to create the necessary migrations for using the active record adapter:

    $ rails g flipper:active_record_v2

Once you have created and executed the migration, you can use the active record adapter like so:

```ruby
require 'flipper/adapters/v2/active_record'
adapter = Flipper::Adapters::V2::ActiveRecord.new
flipper = Flipper.new(adapter)
# profit...
```

### V1

For your convenience a migration generator is provided to create the necessary migrations for using the active record adapter:

    $ rails g flipper:active_record

Once you have created and executed the migration, you can use the active record adapter like so:

```ruby
require 'flipper/adapters/active_record'
adapter = Flipper::Adapters::ActiveRecord.new
flipper = Flipper.new(adapter)
# profit...
```

## Internals

You can learn more about the internals of the adapter by [checking out the example](../../examples/active_record/internals.rb).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
