require './example_setup'

require 'flipper'
require 'flipper/adapters/memory'

adapter = Flipper::Adapters::Memory.new
stats = Flipper::Feature.new(:stats, adapter)

# Some class that represents what will be trying to do something
class User
  def initialize(id)
    @id = id
  end

  def to_flipper_actor
    @to_flipper_actor ||= Flipper::Types::Actor.new(@id)
  end
end

user1 = User.new(1)
user2 = User.new(2)

puts "Stats for user1: #{stats.enabled?(user1.to_flipper_actor)}"
puts "Stats for user2: #{stats.enabled?(user2.to_flipper_actor)}"

puts "\nEnabling stats for user1...\n\n"
stats.enable(user1.to_flipper_actor)

puts "Stats for user1: #{stats.enabled?(user1.to_flipper_actor)}"
puts "Stats for user2: #{stats.enabled?(user2.to_flipper_actor)}"
