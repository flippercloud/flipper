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

pitt = User.new(1)
clooney = User.new(10)

puts "Stats for pitt: #{stats.enabled?(pitt.to_flipper_actor)}"
puts "Stats for clooney: #{stats.enabled?(clooney.to_flipper_actor)}"

puts "\nEnabling stats for 5 percent...\n\n"
stats.enable(Flipper::Types::PercentageOfActors.new(5))

puts "Stats for pitt: #{stats.enabled?(pitt.to_flipper_actor)}"
puts "Stats for clooney: #{stats.enabled?(clooney.to_flipper_actor)}"

puts "\nEnabling stats for 15 percent...\n\n"
stats.enable(Flipper::Types::PercentageOfActors.new(15))

puts "Stats for pitt: #{stats.enabled?(pitt.to_flipper_actor)}"
puts "Stats for clooney: #{stats.enabled?(clooney.to_flipper_actor)}"
