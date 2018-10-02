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

require 'generators/flipper/templates/v2_migration'
CreateFlipperV2Tables.up
