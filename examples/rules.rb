require 'bundler/setup'
require 'flipper'

class User < Struct.new(:id, :flipper_properties)
  include Flipper::Identifier
end

user = User.new(1, {
  "plan" => "basic",
  "age" => 39,
})

p Flipper.enabled?(:something, user)
any_rule = Flipper::Rules::Any.new(
  Flipper::Rules::Condition.new(
    {"type" => "property", "value" => "plan"},
    {"type" => "operator", "value" => "eq"},
    {"type" => "string", "value" => "basic"}
  ),
  Flipper::Rules::Condition.new(
    {"type" => "property", "value" => "age"},
    {"type" => "operator", "value" => "gte"},
    {"type" => "integer", "value" => 21}
  )
)

Flipper.enable_rule :something, any_rule
p Flipper.enabled?(:something, user)

Flipper.disable_rule :something, any_rule
p Flipper.enabled?(:something, user)
