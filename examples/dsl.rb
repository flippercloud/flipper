require './example_setup'

require 'flipper'
require 'flipper/adapters/memory'

adapter = Flipper::Adapters::Memory.new
flipper = Flipper.new(adapter)

# create a thing with an identifier
class Person
  attr_reader :id

  def initialize(id)
    @id = id
  end
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
puts "stats.disabled?: #{stats.disabled?}"
puts "stats.enabled? person: #{stats.enabled? person}"
puts "stats.disabled? person: #{stats.disabled? person}"
puts

# get an instance of the percentage of random type set to 5
puts flipper.random(5).inspect

# get an instance of the percentage of actors type set to 15
puts flipper.actors(15).inspect

# get an instance of an actor using an object that responds to id
responds_to_id = Struct.new(:id).new(10)
puts flipper.actor(responds_to_id).inspect

# get an instance of an actor using an object that responds to identifier
responds_to_identifier = Struct.new(:identifier).new(11)
puts flipper.actor(responds_to_identifier).inspect

# get an instance of an actor using a number
puts flipper.actor(23).inspect

# register a top level group
admins = Flipper.register(:admins) { |actor|
  actor.respond_to?(:admin?) && actor.admin?
}
puts admins.inspect

# get instance of registered group by name
puts Flipper.group(:admins).inspect
