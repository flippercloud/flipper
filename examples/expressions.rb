require 'bundler/setup'
require 'flipper'

def assert(value)
  if value
    p value
  else
    puts "Expected true but was #{value}. Please correct."
    exit 1
  end
end

def refute(value)
  if value
    puts "Expected false but was #{value}. Please correct."
    exit 1
  else
    p value
  end
end

def reset
  Flipper.disable_expression :something
end

class User < Struct.new(:id, :flipper_properties)
  include Flipper::Identifier
end

class Org < Struct.new(:id, :flipper_properties)
  include Flipper::Identifier
end

NOW = Time.now.to_i
DAY = 60 * 60 * 24

org = Org.new(1, {
  "type" => "Org",
  "id" => 1,
  "now" => NOW,
})

user = User.new(1, {
  "type" => "User",
  "id" => 1,
  "plan" => "basic",
  "age" => 39,
  "team_user" => true,
  "now" => NOW,
})

admin_user = User.new(2, {
  "type" => "User",
  "id" => 2,
  "admin" => true,
  "team_user" => true,
  "now" => NOW,
})

other_user = User.new(3, {
  "type" => "User",
  "id" => 3,
  "plan" => "plus",
  "age" => 18,
  "org_admin" => true,
  "now" => NOW - DAY,
})

age_expression = Flipper.property(:age).gte(21)
plan_expression = Flipper.property(:plan).eq("basic")
admin_expression = Flipper.property(:admin).eq(true)

puts "Single Expression"
refute Flipper.enabled?(:something, user)

puts "Enabling single expression"
Flipper.enable :something, plan_expression
assert Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Disabling single expression"
reset
refute Flipper.enabled?(:something, user)

puts "\n\nAny Expression"
any_expression = Flipper.any(plan_expression, age_expression)
refute Flipper.enabled?(:something, user)

puts "Enabling any expression"
Flipper.enable :something, any_expression
assert Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Disabling any expression"
reset
refute Flipper.enabled?(:something, user)

puts "\n\nAll Expression"
all_expression = Flipper.all(plan_expression, age_expression)
refute Flipper.enabled?(:something, user)

puts "Enabling all expression"
Flipper.enable :something, all_expression
assert Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Disabling all expression"
reset
refute Flipper.enabled?(:something, user)

puts "\n\nNested Expression"
nested_expression = Flipper.any(admin_expression, all_expression)
refute Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Enabling nested expression"
Flipper.enable :something, nested_expression
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Disabling nested expression"
reset
refute Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "\n\nBoolean Expression"
boolean_expression = Flipper.boolean(true)
Flipper.enable :something, boolean_expression
assert Flipper.enabled?(:something)
assert Flipper.enabled?(:something, user)
reset

puts "\n\nSet of Actors Expression"
set_of_actors_expression = Flipper.any(
  Flipper.property(:flipper_id).eq("User;1"),
  Flipper.property(:flipper_id).eq("User;3"),
)
Flipper.enable :something, set_of_actors_expression
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, other_user)
refute Flipper.enabled?(:something, admin_user)
reset

puts "\n\n% of Actors Expression"
percentage_of_actors = Flipper.property(:flipper_id).percentage_of_actors(30)
Flipper.enable :something, percentage_of_actors
refute Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, other_user)
assert Flipper.enabled?(:something, admin_user)
reset

puts "\n\n% of Actors Per Type Expression"
percentage_of_actors_per_type = Flipper.any(
  Flipper.all(
    Flipper.property(:type).eq("User"),
    Flipper.property(:flipper_id).percentage_of_actors(40),
  ),
  Flipper.all(
    Flipper.property(:type).eq("Org"),
    Flipper.property(:flipper_id).percentage_of_actors(10),
  )
)
Flipper.enable :something, percentage_of_actors_per_type
refute Flipper.enabled?(:something, user) # not in the 40% enabled for Users
assert Flipper.enabled?(:something, other_user)
assert Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, org) # not in the 10% of enabled for Orgs
reset

puts "\n\nPercentage of Time Expression"
percentage_of_time_expression = Flipper.random(100).lt(50)
Flipper.enable :something, percentage_of_time_expression
results = (1..10000).map { |n| Flipper.enabled?(:something, user) }
enabled, disabled = results.partition { |r| r }
p enabled: enabled.size
p disabled: disabled.size
assert (4_700..5_200).include?(enabled.size)
assert (4_700..5_200).include?(disabled.size)
reset

puts "\n\nChanging single expression to all expression"
Flipper.enable :something, plan_expression
Flipper.enable :something, Flipper.expression(:something).all.add(age_expression)
assert Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "\n\nChanging single expression to any expression"
Flipper.enable :something, plan_expression
Flipper.enable :something, Flipper.expression(:something).any.add(age_expression, admin_expression)
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "\n\nChanging single expression to any expression by adding to condition"
Flipper.enable :something, plan_expression
Flipper.enable :something, Flipper.expression(:something).add(admin_expression)
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "\n\nEnabling based on time"
scheduled_time_expression = Flipper.property(:now).gte(NOW)
Flipper.enable :something, scheduled_time_expression
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)
