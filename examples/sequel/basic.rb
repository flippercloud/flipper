require 'bundler/setup'
require 'sequel'
Sequel::Model.db =  Sequel.sqlite(':memory:')
Sequel.extension :migration, :core_extensions

require 'generators/flipper/templates/sequel_migration'
CreateFlipperTablesSequel.new(Sequel::Model.db).up

require 'flipper/adapters/sequel'

Flipper[:stats].enable

if Flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end

Flipper[:stats].disable

if Flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end
