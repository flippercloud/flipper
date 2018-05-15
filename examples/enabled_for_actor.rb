require File.expand_path('../example_setup', __FILE__)

require 'flipper'

# Some class that represents what will be trying to do something
class User
  attr_reader :id

  def initialize(id, admin)
    @id = id
    @admin = admin
  end

  def admin?
    @admin
  end

  # Must respond to flipper_id
  alias_method :flipper_id, :id
end

user1 = User.new(1, true)
user2 = User.new(2, false)

# pick an adapter
adapter = Flipper::Adapters::Memory.new

# get a handy dsl instance
flipper = Flipper.new(adapter)

Flipper.register :admins do |actor|
  actor.admin?
end

flipper[:search].enable
flipper[:stats].enable_actor user1
flipper[:pro_stats].enable_percentage_of_actors 50
flipper[:tweets].enable_group :admins
flipper[:posts].enable_actor user2

pp flipper.features.select { |feature| feature.enabled?(user1) }.map(&:name)
pp flipper.features.select { |feature| feature.enabled?(user2) }.map(&:name)
