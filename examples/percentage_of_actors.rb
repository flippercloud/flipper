require File.expand_path('../example_setup', __FILE__)

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

  # Must respond to flipper_id
  alias_method :flipper_id, :id
end

pitt = User.new(1)
clooney = User.new(10)

puts "Stats for pitt: #{stats.enabled?(pitt)}"
puts "Stats for clooney: #{stats.enabled?(clooney)}"

puts "\nEnabling stats for 5 percent...\n\n"
stats.enable(Flipper::Types::PercentageOfActors.new(5))

puts "Stats for pitt: #{stats.enabled?(pitt)}"
puts "Stats for clooney: #{stats.enabled?(clooney)}"

puts "\nEnabling stats for 50 percent...\n\n"
stats.enable(Flipper::Types::PercentageOfActors.new(50))

puts "Stats for pitt: #{stats.enabled?(pitt)}"
puts "Stats for clooney: #{stats.enabled?(clooney)}"
