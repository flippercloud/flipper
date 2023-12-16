require 'bundler/setup'
require 'flipper'

adapter = Flipper::Adapters::Strict.new(Flipper::Adapters::Memory.new)
flipper = Flipper.new(adapter)

begin
  puts "Checking :unknown_feature, which should raise an error."
  flipper.enabled?(:unknown_feature)
  warn "An error was not raised, but should have been"
  exit 1
rescue Flipper::Adapters::Strict::NotFound => exception
  puts "Ok, the exepcted error was raised: #{exception.message}"
end

puts "Flipper.add(:new_feature)"
flipper.add(:new_feature)
puts "Flipper.enabled?(:new_feature) => #{flipper.enabled?(:new_feature)}"
