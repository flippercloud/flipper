# Gates

Out of the box several types of enabling are supported. They are checked in this order:

## 1. Boolean

All on or all off. Think top level things like `:stats`, `:search`, `:logging`, etc. Also, an easy way to release a new feature as once a feature is boolean enabled it is on for every situation.

```ruby
flipper = Flipper.new(adapter)
flipper[:stats].enable # turn on
flipper[:stats].disable # turn off
flipper[:stats].enabled? # check
```

## 2. Individual Actor

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

# you can also use shortcut methods
flipper.enable_actor :search, user
flipper.disable_actor :search, user
flipper[:search].enable_actor user
flipper[:search].disable_actor user
```

The key is to make sure you do not enable two different types of objects for the same feature. Imagine that user has a `flipper_id` of 6 and group has a `flipper_id` of 6. Enabling search for user would automatically enable it for group, as they both have a `flipper_id` of 6.

The one exception to this rule is if you have globally unique `flipper_ids`, such as UUIDs. If your `flipper_ids` are unique globally in your entire system, enabling two different types should be safe. Another way around this is to prefix the `flipper_id` with the class name like this:

```ruby
class User
  def flipper_id
    "User;#{id}"
  end
end

class Group
  def flipper_id
    "Group;#{id}"
  end
end
```

## 3. Percentage of Actors

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

# you can also use shortcut methods
flipper.enable_percentage_of_actors :search, 10
flipper.disable_percentage_of_actors :search # sets to 0
flipper[:search].enable_percentage_of_actors 10
flipper[:search].disable_percentage_of_actors # sets to 0
```

## 4. Percentage of Time

Turn this on for a percentage of time. Think load testing new features behind the scenes and such.

```ruby
flipper = Flipper.new(adapter)

# get percentage of time instance set to 5
percentage = flipper.time(5)

# Register a feature called logging and turn it on for 5 percent of the time.
# This could be on during one request and off the next
# could even be on first time in request and off second time
flipper[:logging].enable percentage
flipper[:logging].enabled? # this will return true 5% of the time.

# you can also use shortcut methods
flipper.enable_percentage_of_time :search, 5 # registers a feature called "search" and enables it 5% of the time
flipper.disable_percentage_of_time :search # sets to 0
flipper[:search].enable_percentage_of_time 5
flipper[:search].disable_percentage_of_time # sets to 0
```

Timeness is not a good idea for enabling new features in the UI. Most of the time you want a feature on or off for a user, but there are definitely times when I have found percentage of time to be very useful.

## 5. Group

Turn on feature based on the return value of block. Super flexible way to turn on a feature for multiple things (users, people, accounts, etc.) as long as the thing returns true when passed to the block.

```ruby
# this registers a group
Flipper.register(:admins) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end

flipper = Flipper.new(adapter)

flipper[:stats].enable flipper.group(:admins) # This registers a stats feature and turns it on for admins (which is anything that returns true from the registered block).
flipper[:stats].disable flipper.group(:admins) # turn off the stats feature for admins

person = Person.find(params[:id])
flipper[:stats].enabled? person # check if enabled, returns true if person.admin? is true

# you can also use shortcut methods. This also registers a stats feature and turns it on for admins.
flipper.enable_group :stats, :admins
person = Person.find(params[:id])
flipper[:stats].enabled? person # same as above. check if enabled, returns true if person.admin? is true

flipper.disable_group :stats, :admins
flipper[:stats].enable_group :admins
flipper[:stats].disable_group :admins
```

Here's a quick explanation of the above code block:

```
Flipper.register(:admins) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end
```
- The above first registers a group called `admins` which essentially saves a [Proc](http://www.eriktrautman.com/posts/ruby-explained-blocks-procs-and-lambdas-aka-closures) to be called later. The `actor` is an instance of the `Flipper::Types::Actor` that wraps the thing being checked against and `actor.thing` is the original object being checked. 

```
flipper[:stats].enable flipper.group(:admins)
```

- The above enables the stats feature to any object that returns true from the `:admins` proc.

```
person = Person.find(params[:id])
flipper[:stats].enabled? person # check if person is enabled, returns true if person.admin? is true
```

When the `person` object is passed to the `enabled?` method, it is then passed into the proc. If the proc returns true, the entire statement returns true and so `flipper[:stats].enabled? person` returns true. Whatever logic follows this conditional check is then executed.

There is no requirement that the thing yielded to the block be a user model or whatever. It can be anything you want, therefore it is a good idea to check that the thing passed into the group block actually responds to what you are trying to do in the `register` proc.

In your application code, you can do something like this now:

```
if flipper[:stats].enabled?(some_admin)
  # do thing...
else
  # do not do thing
end
```
