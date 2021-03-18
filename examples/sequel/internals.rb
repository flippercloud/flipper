require 'bundler/setup'
require 'sequel'
Sequel::Model.db =  Sequel.sqlite(':memory:')
Sequel.extension :migration, :core_extensions

require 'generators/flipper/templates/sequel_migration'
CreateFlipperTablesSequel.new(Sequel::Model.db).up

require 'flipper/adapters/sequel'
adapter = Flipper::Adapters::Sequel.new
flipper = Flipper.new(adapter)

# Register a few groups.
Flipper.register(:admins) { |thing| thing.admin? }
Flipper.register(:early_access) { |thing| thing.early_access? }

# Create a user class that has flipper_id instance method.
User = Struct.new(:flipper_id)

flipper[:stats].enable
flipper[:stats].enable_group :admins
flipper[:stats].enable_group :early_access
flipper[:stats].enable_actor User.new('25')
flipper[:stats].enable_actor User.new('90')
flipper[:stats].enable_actor User.new('180')
flipper[:stats].enable_percentage_of_time 15
flipper[:stats].enable_percentage_of_actors 45

flipper[:search].enable

puts 'all rows in features table'
pp Flipper::Adapters::Sequel::Feature.all
#[#<Flipper::Adapters::Sequel::Feature @values={:key=>"stats", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
# #<Flipper::Adapters::Sequel::Feature @values={:key=>"search", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>]
puts

puts 'all rows in gates table'
pp Flipper::Adapters::Sequel::Gate.all
# [#<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"boolean", :value=>"true", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"groups", :value=>"admins", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"groups", :value=>"early_access", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"actors", :value=>"25", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"actors", :value=>"90", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"actors", :value=>"180", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"percentage_of_time", :value=>"15", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"percentage_of_actors", :value=>"45", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"search", :key=>"boolean", :value=>"true", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>]
puts

puts 'flipper get of feature'
pp adapter.get(flipper[:stats])
# {:boolean=>"true",
#  :groups=>#<Set: {"admins", "early_access"}>,
#  :actors=>#<Set: {"180", "25", "90"}>,
#  :percentage_of_actors=>"45",
#  :percentage_of_time=>"15"}
