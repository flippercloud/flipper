![flipper logo](https://raw.github.com/jnunemaker/flipper-ui/master/lib/flipper/ui/public/flipper/images/logo.png)

Feature flipping is the act of enabling or disabling features or parts of your application, ideally without re-deploying or changing anything in your code base.

The goal of this gem is to make turning features on or off so easy that everyone does it. Whatever your data store, throughput, or experience, feature flipping should be easy and have minimal impact on your application.

## Installation

Add this line to your application's Gemfile:

    gem 'flipper'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper

## Coming Soon™

* [Web UI](https://github.com/jnunemaker/flipper-ui) (think resque UI for features toggling/status)

## Usage

The goal of the API for flipper was to have everything revolve around features and what ways they can be enabled. Start with top level and dig into a feature, then dig in further and enable that feature for a given type of access, as opposed to thinking about how the feature will be accessed first (ie: stats.enable vs activate_group(:stats, ...)).

```ruby
require 'flipper'

# pick an adapter
require 'flipper/adapters/memory'
adapter = Flipper::Adapters::Memory.new

# get a handy dsl instance
flipper = Flipper.new(adapter)

# grab a feature
search = flipper[:search]

# check if that feature is enabled
if search.enabled?
  puts 'Search away!'
else
  puts 'No search for you!'
end

puts 'Enabling Search...'
search.enable

# check if that feature is enabled again
if search.enabled?
  puts 'Search away!'
else
  puts 'No search for you!'
end
```

Of course there are more [examples for you to peruse](https://github.com/jnunemaker/flipper/tree/master/examples).

## Types

Out of the box several types of enabling are supported. They are checked in this order.

### 1. Boolean

All on or all off. Think top level things like :stats, :search, :logging, etc. Also, an easy way to release a new feature as once a feature is boolean enabled it is on for every situation.

```ruby
flipper = Flipper.new(adapter)
flipper[:stats].enable # turn on
flipper[:stats].disable # turn off
flipper[:stats].enabled? # check
```

### 2. Group

Turn on feature based on value of block. Super flexible way to turn on a feature for multiple things (users, people, accounts, etc.)

```ruby
Flipper.register(:admins) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end

flipper = Flipper.new(adapter)
flipper[:stats].enable flipper.group(:admins) # turn on for admins
flipper[:stats].disable flipper.group(:admins) # turn off for admins
person = Person.find(params[:id])
flipper[:stats].enabled? person # check if enabled, returns true if person.admin? is true
```

There is no requirement that the thing yielded to the block be a user model or whatever. It can be anything you want therefore it is a good idea to check that the thing passed into the group block actually responds to what you are trying.

### 3. Individual Actor

Turn feature on for individual thing. Think enable feature for someone to test or for a buddy. The only requirement for an individual actor is that it must respond to `flipper_id`.

```ruby
flipper = Flipper.new(adapter)

flipper[:stats].enable user
flipper[:stats].enabled? user # true

flipper[:stats].disable user
flipper[:stats].enabled? user # false

# you can enable anything, does not need to be user or person
flipper[:search].enable group
flipper[:search].enabled? group
```

The key is to make sure you do not enable two different types of objects for the same feature. Imagine that user has a flipper_id of 6 and group has a flipper_id of 6. Enabling search for user would automatically enable it for group, as they both have a flipper_id of 6.

The one exception to this rule is if you have globally unique flipper_ids, such as uuid's. If your flipper_ids are unique globally in your entire system, enabling two different types should be safe. Another way around this is to prefix the flipper_id with the class name like this:

```ruby
class User
  def flipper_id
    "User:#{id}"
  end
end

class Group
  def flipper_id
    "Group:#{id}"
  end
end
```

### 4. Percentage of Actors

Turn this on for a percentage of actors (think user, member, account, group, whatever). Consistently on or off for this user as long as percentage increases. Think slow rollout of a new feature to a percentage of things.

```ruby
flipper = Flipper.new(adapter)

# returns a percentage of actors instance set to 10
percentage = flipper.actors(10)

# turn stats on for 10 percent of users in the system
flipper[:stats].enable percentage

# checks if actor's flipper_id is in the enabled percentage by hashing
# user.flipper_id.to_s to ensure enabled distribution is smooth
flipper[:stats].enabled? user

```

### 5. Percentage of Random

Turn this on for a random percentage of time. Think load testing new features behind the scenes and such.

```ruby
flipper = Flipper.new(adapter)

# get percentage of random instance set to 5
percentage = flipper.random(5)

# turn on logging for 5 percent of the time randomly
# could be on during one request and off the next
# could even be on first time in request and off second time
flipper[:logging].enable percentage
```

Randomness is not a good idea for enabling new features in the UI. Most of the time you want a feature on or off for a user, but there are definitely times when I have found percentage of random to be very useful.

## Adapters

I plan on supporting [in-memory](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/memory.rb), [Mongo](https://github.com/jnunemaker/flipper-mongo), and [Redis](https://github.com/jnunemaker/flipper-redis) as adapters for flipper. Others are welcome, so please let me know if you create one.

* [memory adapter](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/memory.rb) - Great for tests.
* [mongo adapter](https://github.com/jnunemaker/flipper-mongo)
* [redis adapter](https://github.com/jnunemaker/flipper-redis)
* [cassanity adapter](https://github.com/jnunemaker/flipper-cassanity)

The basic API for an adapter is this:

* `features` - Get the set of known features.
* `add(feature)` - Add a feature to the set of known features.
* `remove(feature)` - Remove a feature from the set of known features.
* `clear(feature)` - Clear all gate values for a feature.
* `get(feature)` - Get all gate values for a feature.
* `enable(feature, gate, thing)` - Enable a gate for a thing.
* `disable(feature, gate, thing)` - Disable a gate for a thing.

If you would like to make your own adapter, there are shared adapter specs that you can use to verify that you have everything working correctly.

For example, here is what the in-memory adapter spec looks like:

```ruby
require 'helper'
require 'flipper/adapters/memory'

# The shared specs are included with the flipper gem so you can use them in
# separate adapter specific gems.
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Memory do

  # an instance of the new adapter you are trying to create
  subject { described_class.new }

  # include the shared specs that the subject must pass
  it_should_behave_like 'a flipper adapter'
end
```

A good place to start when creating your own adapter is to copy one of the adapters mentioned above and replace the client specific code with whatever client you are attempting to adapt.

I would also recommend setting `fail_fast = true` in your RSpec configuration as that will just give you one failure at a time to work through. It is also handy to have the shared adapter spec file open.

## Optimization

One optimization that flipper provides is a memoizing middleware. The memoizing middleware ensures that you only make one adapter call per feature per request.

This means if you check the same feature over and over, it will only make one mongo, redis, or whatever call per feature for the length of the request.

You can use the middleware from a Rails initializer like so:

```ruby
# create flipper dsl instance, see above Usage for more details
flipper = Flipper.new(...)

require 'flipper/middleware/memoizer'
config.middleware.use Flipper::Middleware::Memoizer, flipper
```

If you set your flipper instance up in an initializer, you can pass a block to the middleware and it will lazily load the instance the first time the middleware is invoked.

```ruby
# config/initializers/flipper.rb
$flipper = Flipper.new(...)

# config/application.rb
config.middleware.use Flipper::Middleware::Memoizer, lambda { $flipper }
```

**Note**: Be sure that the middlware is high enough up in your stack that all feature checks are wrapped.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
