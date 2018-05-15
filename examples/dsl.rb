require File.expand_path('../example_setup', __FILE__)

require 'flipper'

adapter = Flipper::Adapters::Memory.new
flipper = Flipper.new(adapter)

# create a thing with an identifier
class Person
  attr_reader :id

  def initialize(id)
    @id = id
  end

  # Must respond to flipper_id
  alias_method :flipper_id, :id
end

person = Person.new(1)

puts "Stats are disabled by default\n\n"

# is a feature enabled
puts "flipper.enabled? :stats: #{flipper.enabled? :stats}"

# is a feature on or off for a particular person
puts "flipper.enabled? :stats, person: #{flipper.enabled? :stats, person}"

# get at a feature
puts "\nYou can also get an individual feature like this:\nstats = flipper[:stats]\n\n"
stats = flipper[:stats]

# is that feature enabled
puts "stats.enabled?: #{stats.enabled?}"

# is that feature enabled for a particular person
puts "stats.enabled? person: #{stats.enabled? person}"

# enable a feature by name
puts "\nEnabling stats\n\n"
flipper.enable :stats

# or, you can use the feature to enable
stats.enable

puts "stats.enabled?: #{stats.enabled?}"
puts "stats.enabled? person: #{stats.enabled? person}"

# oh, no, let's turn this baby off
puts "\nDisabling stats\n\n"
flipper.disable :stats

# or we can disable using feature obviously
stats.disable

puts "stats.enabled?: #{stats.enabled?}"
puts "stats.enabled? person: #{stats.enabled? person}"
puts

# get an instance of the percentage of time type set to 5
puts flipper.time(5).inspect

# get an instance of the percentage of actors type set to 15
puts flipper.actors(15).inspect

# get an instance of an actor using an object that responds to flipper_id
responds_to_flipper_id = Struct.new(:flipper_id).new(10)
puts flipper.actor(responds_to_flipper_id).inspect

# get an instance of an actor using an object
thing = Struct.new(:flipper_id).new(22)
puts flipper.actor(thing).inspect

# register a top level group
admins = Flipper.register(:admins) { |actor|
  actor.respond_to?(:admin?) && actor.admin?
}
puts admins.inspect

# get instance of registered group by name
puts Flipper.group(:admins).inspect
