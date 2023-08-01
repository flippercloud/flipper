require 'bundler/setup'
require_relative 'active_record/ar_setup'
require 'flipper'
require 'flipper/adapters/redis'
require 'flipper/adapters/active_record'

# Say you have production...
production_adapter = Flipper::Adapters::Memory.new
production = Flipper.new(production_adapter)

# And production has some stuff enabled...
production.enable(:search)
production.enable_percentage_of_time(:verbose_logging, 5)
production.enable_percentage_of_actors(:new_feature, 5)
production.enable_actor(:issues, Flipper::Actor.new('1'))
production.enable_actor(:issues, Flipper::Actor.new('2'))
production.enable_group(:request_tracing, :staff)

# And you would like to mirror production to staging...
staging_adapter = Flipper::Adapters::Memory.new
staging = Flipper.new(staging_adapter)
staging_export = staging.export

puts "Here is the state of the world for staging and production..."
puts "Staging"
staging.features.each do |feature|
  pp feature: feature.key, values: feature.gate_values
end
puts "Production"
production.features.each do |feature|
  pp feature: feature.key, values: feature.gate_values
end

# NOTE: This wipes active record clean and copies features/gates from redis into active record.
puts "Mirroring production to staging..."
staging.import(production.export)
puts "Staging is now identical to Production."

puts "Staging"
staging.features.each do |feature|
  pp feature: feature.key, values: feature.gate_values
end
puts "Production"
production.features.each do |feature|
  pp feature: feature.key, values: feature.gate_values
end

puts "Restoring staging to original state..."
staging.import(staging_export)
puts "Staging restored."

puts "Staging"
staging.features.each do |feature|
  pp feature: feature.key, values: feature.gate_values
end
puts "Production"
production.features.each do |feature|
  pp feature: feature.key, values: feature.gate_values
end
