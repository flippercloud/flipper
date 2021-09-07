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

class User < Struct.new(:id, :flipper_properties)
  include Flipper::Identifier
end

class Org < Struct.new(:id, :flipper_properties)
  include Flipper::Identifier
end

org = Org.new(1, {
  "type" => "Org",
  "id" => 1,
})

user = User.new(1, {
  "type" => "User",
  "id" => 1,
  "plan" => "basic",
  "age" => 39,
  "roles" => ["team_user"]
})

admin_user = User.new(2, {
  "type" => "User",
  "id" => 2,
  "roles" => ["admin", "team_user"],
})

other_user = User.new(3, {
  "type" => "User",
  "id" => 3,
  "plan" => "plus",
  "age" => 18,
  "roles" => ["org_admin"]
})

age_rule = Flipper.property(:age).gte(21)
plan_rule = Flipper.property(:plan).eq("basic")
admin_rule = Flipper.object("admin").in(Flipper.property(:roles))

puts "Single Rule"
refute Flipper.enabled?(:something, user)

puts "Enabling single rule"
Flipper.enable_rule :something, plan_rule
assert Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "Disabling single rule"
Flipper.disable_rule :something, plan_rule
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
Flipper.disable_rule :something, any_rule
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
Flipper.disable_rule :something, all_rule
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
Flipper.disable_rule :something, nested_rule
refute Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, admin_user)
refute Flipper.enabled?(:something, other_user)

puts "\n\nBoolean Rule"
boolean_rule = Flipper::Rules::Condition.new(
  {"type" => "boolean", "value" => true},
  {"type" => "operator", "value" => "eq"},
  {"type" => "boolean", "value" => true}
)
Flipper.enable_rule :something, boolean_rule
assert Flipper.enabled?(:something)
assert Flipper.enabled?(:something, user)
Flipper.disable_rule :something, boolean_rule

puts "\n\nSet of Actors Rule"
set_of_actors_rule = Flipper.property(:flipper_id).in(["User;1", "User;3"])
Flipper.enable_rule :something, set_of_actors_rule
assert Flipper.enabled?(:something, user)
assert Flipper.enabled?(:something, other_user)
refute Flipper.enabled?(:something, admin_user)
Flipper.disable_rule :something, set_of_actors_rule

puts "\n\n% of Actors Rule"
percentage_of_actors = Flipper.property(:flipper_id).percentage(30)
Flipper.enable_rule :something, percentage_of_actors
refute Flipper.enabled?(:something, user)
refute Flipper.enabled?(:something, other_user)
assert Flipper.enabled?(:something, admin_user)
Flipper.disable_rule :something, percentage_of_actors

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
Flipper.disable_rule :something, percentage_of_actors_per_type

puts "\n\nPercentage of Time Rule"
percentage_of_time_rule = Flipper::Rules::Condition.new(
  {"type" => "random", "value" => 100},
  {"type" => "operator", "value" => "lt"},
  {"type" => "integer", "value" => 50}
)
Flipper.enable_rule :something, percentage_of_time_rule
results = (1..10000).map { |n| Flipper.enabled?(:something, user) }
enabled, disabled = results.partition { |r| r }
assert (4500..5500).include?(enabled.size)
assert (4500..5500).include?(disabled.size)
Flipper.disable_rule :something, percentage_of_time_rule
