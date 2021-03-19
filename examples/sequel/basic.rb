require 'bundler/setup'
require 'sequel'
Sequel::Model.db =  Sequel.sqlite(':memory:')
Sequel.extension :migration, :core_extensions

require 'generators/flipper/templates/sequel_migration'
CreateFlipperTablesSequel.new(Sequel::Model.db).up

require 'flipper/adapters/sequel'
adapter = Flipper::Adapters::Sequel.new
flipper = Flipper.new(adapter)

flipper[:stats].enable

if flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end

flipper[:stats].disable

if flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end
