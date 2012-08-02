require './example_setup'

require 'flipper'
require 'flipper/adapters/memory'

adapter = Flipper::Adapters::Memory.new
flipper = Flipper.new(adapter)
stats = flipper[:stats]

# Register group
Flipper.register(:admins) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end

# Some class that represents actor that will be trying to do something
class User
  def initialize(admin)
    @admin = admin
  end

  def admin?
    @admin == true
  end
end

admin = User.new(true)
non_admin = User.new(false)

puts "Stats for admin: #{stats.enabled?(admin)}"
puts "Stats for non_admin: #{stats.enabled?(non_admin)}"

puts "\nEnabling Stats for admins...\n\n"
stats.enable(flipper.group(:admins))

puts "Stats for admin: #{stats.enabled?(admin)}"
puts "Stats for non_admin: #{stats.enabled?(non_admin)}"
