# Gates

Out of the box several types of enabling are supported. They are checked in this order:

## 1. Boolean

All on or all off. Think top level things like `:stats`, `:search`, `:logging`, etc. Also, an easy way to release a new feature as once a feature is boolean enabled it is on for every situation.

```ruby
Flipper.enable :stats # turn on
Flipper.disable :stats # turn off
Flipper.enabled? :stats # check
```

## 2. Individual Actor

Turn feature on for individual thing. Think enable feature for someone to test or for a buddy.

```ruby
Flipper.enable_actor :stats, user
Flipper.enabled? :stats, user # true

Flipper.disable_actor :stats, user
Flipper.enabled? :stats, user # false

# you can enable anything, does not need to be user or person
Flipper.enable_actor :search, organization
Flipper.enabled? :search, organization

# you can also save a reference to a specific feature
feature = Flipper[:search]

feature.enable_actor user
feature.enabled? user # true
feature.disable_actor user
```

The only requirement for an individual actor is that it must have a unique `flipper_id`. Include the `Flipper::Identifier` module for a default implementation which combines the class name and `id` (e.g. `User;6`).

```ruby
class User < Struct.new(:id)
  include Flipper::Identifier
end

User.new(5).flipper_id # => "User;5"
```

You can also define your own implementation:

```
class Organization < Struct.new(:uuid)
  def flipper_id
    uuid
  end
end

Organization.new("DEB3D850-39FB-444B-A1E9-404A990FDBE0").flipper_id
# => "DEB3D850-39FB-444B-A1E9-404A990FDBE0"
```

Just make sure each type of object has a unique `flipper_id`.

## 3. Percentage of Actors

Turn this on for a percentage of actors (think user, member, account, group, whatever). Consistently on or off for this user as long as percentage increases. Think slow rollout of a new feature to a percentage of things.

```ruby
# turn stats on for 10 percent of users in the system
Flipper.enable :stats, Flipper.actors(10)
# or
Flipper.enable_percentage_of_actors :stats, 10

# checks if actor's flipper_id is in the enabled percentage by hashing
# user.flipper_id.to_s to ensure enabled distribution is smooth
Flipper.enabled? :stats, user

Flipper.disable_percentage_of_actors :search # sets to 0
# or
Flipper.disable :stats, Flipper.actors(0)

# you can also save a reference to a specific feature
feature = Flipper[:search]
feature.enable_percentage_of_actors 10
feature.enabled? user
feature.disable_percentage_of_actors # sets to 0
```

## 4. Percentage of Time

Turn this on for a percentage of time. Think load testing new features behind the scenes and such.

```ruby
# Register a feature called logging and turn it on for 5 percent of the time.
# This could be on during one request and off the next
# could even be on first time in request and off second time
Flipper.enable_percentage_of_time :logging, 5

Flipper.enabled? :logging # this will return true 5% of the time.

Flipper.disable_percentage_of_time :logging # sets to 0

# you can also save a reference to a specific feature
feature = Flipper[:search]
feature.enable_percentage_of_time, 5
feature.enabled?
feature.disable_percentage_of_time
```

Timeness is not a good idea for enabling new features in the UI. Most of the time you want a feature on or off for a user, but there are definitely times when I have found percentage of time to be very useful.

## 5. Group

Turn on feature based on the return value of block. Super flexible way to turn on a feature for multiple things (users, people, accounts, etc.) as long as the thing returns true when passed to the block.

```ruby
# this registers a group
Flipper.register(:admins) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end

Flipper.enable_group :stats, :admins # This registers a stats feature and turns it on for admins (which is anything that returns true from the registered block).
Flipper.disable_group :stats, :admins # turn off the stats feature for admins

person = Person.find(params[:id])
Flipper.enabled? :stats, person # check if enabled, returns true if person.admin? is true


# you can also use shortcut methods. This also registers a stats feature and turns it on for admins.
feature = Flipper[:search]
feature.enable_group :admins
feature.enabled? person
feature.disable_group :admins
```

Here's a quick explanation of the above code block:

```ruby
Flipper.register(:admins) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end
```
- The above first registers a group called `admins` which essentially saves a [Proc](http://www.eriktrautman.com/posts/ruby-explained-blocks-procs-and-lambdas-aka-closures) to be called later. The `actor` is an instance of the `Flipper::Types::Actor` that wraps the thing being checked against and `actor.thing` is the original object being checked.

```ruby
Flipper.enable_group :stats, :admins
```

- The above enables the stats feature to any object that returns true from the `:admins` proc.

```ruby
person = Person.find(params[:id])
Flipper.enabled? :stats, person # check if person is enabled, returns true if person.admin? is true
```

When the `person` object is passed to the `enabled?` method, it is then passed into the proc. If the proc returns true, the entire statement returns true and so `Flipper[:stats].enabled? person` returns true. Whatever logic follows this conditional check is then executed.

There is no requirement that the thing yielded to the block be a user model or whatever. It can be anything you want, therefore it is a good idea to check that the thing passed into the group block actually responds to what you are trying to do in the `register` proc.

In your application code, you can do something like this now:

```ruby
if Flipper.enabled? :stats, some_admin
  # do thing...
else
  # do not do thing
end
```
