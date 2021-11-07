require 'bundler/setup'
require 'flipper'

def assert(value)
  p value
  unless value
    puts "#{value} expected to be true but was false. Please correct."
    exit 1
  end
end

def refute(value)
  p value
  if value
    puts "#{value} expected to be false but was true. Please correct."
    exit 1
  end
end

def reset
  Flipper.disable_rule :something
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
  "now" => NOW + DAY,
})

age_rule = Flipper.property(:age).gte(21)
plan_rule = Flipper.property(:plan).eq("basic")
admin_rule = Flipper.property(:admin).eq(true)

puts "Single Rule"
refute Flipper.enabled?(:something, user)

puts "Enabling single rule"
Flipper.enable_rule :something, plan_rule
assert Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Disabling single rule"
reset
refute Flipper.enabled?(:something, user)

puts "\n\nAny Rule"
any_rule = Flipper.any(plan_rule, age_rule)
refute Flipper.enabled?(:something, user)

puts "Enabling any rule"
Flipper.enable_rule :something, any_rule
assert Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Disabling any rule"
reset
refute Flipper.enabled?(:something, user)

puts "\n\nAll Rule"
all_rule = Flipper.all(plan_rule, age_rule)
refute Flipper.enabled?(:something, user)

puts "Enabling all rule"
Flipper.enable_rule :something, all_rule
assert Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Disabling all rule"
reset
refute Flipper.enabled?(:something, user)

puts "\n\nNested Rule"
nested_rule = Flipper.any(admin_rule, all_rule)
refute Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Enabling nested rule"
Flipper.enable_rule :something, nested_rule
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Disabling nested rule"
reset
refute Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "\n\nBoolean Rule"
boolean_rule = Flipper.object(true).eq(true)
Flipper.enable_rule :something, boolean_rule
assert Flipper.enabled?(:something)
assert Flipper.enabled?(:something, user)
reset

puts "\n\nSet of Actors Rule"
set_of_actors_rule = Flipper.any(
  Flipper.property(:flipper_id).eq("User;1"),
  Flipper.property(:flipper_id).eq("User;3"),
)
Flipper.enable_rule :something, set_of_actors_rule
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, other_user)
refute Flipper.enabled?(:something, admin_user)
reset

puts "\n\n% of Actors Rule"
percentage_of_actors = Flipper.property(:flipper_id).percentage(30)
Flipper.enable_rule :something, percentage_of_actors
refute Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, other_user)
assert Flipper.enabled?(:something, admin_user)
reset

puts "\n\n% of Actors Per Type Rule"
percentage_of_actors_per_type = Flipper.any(
  Flipper.all(
    Flipper.property(:type).eq("User"),
    Flipper.property(:flipper_id).percentage(40),
  ),
  Flipper.all(
    Flipper.property(:type).eq("Org"),
    Flipper.property(:flipper_id).percentage(10),
  )
)
Flipper.enable_rule :something, percentage_of_actors_per_type
refute Flipper.enabled?(:something, user) # not in the 40% enabled for Users
assert Flipper.enabled?(:something, other_user)
assert Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, org) # not in the 10% of enabled for Orgs
reset

puts "\n\nPercentage of Time Rule"
percentage_of_time_rule = Flipper.random(100).lt(50)
Flipper.enable_rule :something, percentage_of_time_rule
results = (1..10000).map { |n| Flipper.enabled?(:something, user) }
enabled, disabled = results.partition { |r| r }
p enabled: enabled.size
p disabled: disabled.size
assert (4_700..5_200).include?(enabled.size)
assert (4_700..5_200).include?(disabled.size)
reset

puts "\n\nChanging single rule to all rule"
Flipper.enable_rule :something, plan_rule
Flipper.enable_rule :something, Flipper.rule(:something).all.add(age_rule)
assert Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "\n\nChanging single rule to any rule"
Flipper.enable_rule :something, plan_rule
Flipper.enable_rule :something, Flipper.rule(:something).any.add(age_rule, admin_rule)
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "\n\nChanging single rule to any rule by adding to condition"
Flipper.enable_rule :something, plan_rule
Flipper.enable_rule :something, Flipper.rule(:something).add(admin_rule)
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "\n\nEnabling based on time"
scheduled_time_rule = Flipper.property(:now).gte(NOW)
Flipper.enable_rule :something, scheduled_time_rule
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)
