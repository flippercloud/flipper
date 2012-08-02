require './example_setup'

require 'flipper'
require 'flipper/adapters/memory'

adapter = Flipper::Adapters::Memory.new
flipper = Flipper.new(adapter)
stats = flipper[:stats]

# Some class that represents what will be trying to do something
class User
  attr_reader :id

  def initialize(id)
    @id = id
  end
end

user1 = User.new(1)
user2 = User.new(2)

puts "Stats for user1: #{stats.enabled?(flipper.actor(user1))}"
puts "Stats for user2: #{stats.enabled?(flipper.actor(user2))}"

puts "\nEnabling stats for user1...\n\n"
stats.enable(flipper.actor(user1))

puts "Stats for user1: #{stats.enabled?(flipper.actor(user1))}"
puts "Stats for user2: #{stats.enabled?(flipper.actor(user2))}"
