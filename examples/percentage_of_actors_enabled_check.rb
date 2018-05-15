require File.expand_path('../example_setup', __FILE__)

require 'flipper'

adapter = Flipper::Adapters::Memory.new
flipper = Flipper.new(adapter)

# Some class that represents what will be trying to do something
class User
  attr_reader :id

  def initialize(id)
    @id = id
  end

  # Must respond to flipper_id
  alias_method :flipper_id, :id
end

# checking a bunch
gate = Flipper::Gates::PercentageOfActors.new
feature_name = "data_migration"
percentage_enabled = 10
total = 20_000
enabled = []

(1..total).each do |id|
  user = User.new(id)
  if gate.open?(user, percentage_enabled, feature_name: feature_name)
    enabled << user
  end
end

p actual: enabled.size, expected: total * (percentage_enabled * 0.01)

# checking one
user = User.new(1)
p user_1_enabled: Flipper::Gates::PercentageOfActors.new.open?(user, percentage_enabled, feature_name: feature_name)
