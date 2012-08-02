# Flipper

Feature flipper for any adapter.

## Usage

```ruby
require 'flipper'
require 'flipper/adapters/memory'

# pick an adapter
adapter = Flipper::Adapters::Memory.new

# get a handy dsl instance
flipper = Flipper.new(adapter)

# grab a feature
search = flipper[:search]

perform = lambda do
  # check if that feature is enabled
  if search.enabled?
    puts 'Search away!'
  else
    puts 'No search for you!'
  end
end

perform.call
puts 'Enabling Search...'
search.enable
perform.call
```

Of course there are more [examples for you to peruse](https://github.com/jnunemaker/flipper/tree/master/examples).

## Types

Out of the box several types of enabling are supported:

* Boolean - All on or all off.
* Group - Turn on feature based on value of block. Super flexible way to turn on a feature for multiple things (users, people, accounts, etc.)
* Individual Actor - Turn on for individual thing. Think enable feature for someone to test or for a buddy.
* Percentage of Actors - Turn this on for a percentage of actors (think users or people). Consistently on or off for this user as long as percentage increases. Think slow rollout of a new feature to users.
* Percentage of Random - Turn this on for a random percentage of time

## Installation

Add this line to your application's Gemfile:

    gem 'flipper'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
