require 'pathname'
require 'logger'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'active_record'
ActiveRecord::Base.establish_connection({
  adapter: 'sqlite3',
  database: ':memory:',
})

require 'generators/flipper/templates/migration'
CreateFlipperTables.up

require 'flipper/adapters/active_record'
adapter = Flipper::Adapters::ActiveRecord.new
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
