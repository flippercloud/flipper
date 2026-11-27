require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
require 'rails'
require 'rails/test_help'

require 'warning'
Warning.ignore(/lib\/capybara\//)

begin
  ActiveSupport::TestCase.test_order = :random
rescue NoMethodError
  # no biggie, means we are on older version of AS that doesn't have this option
end

def silence
  # Store the original stderr and stdout in order to restore them later
  original_stderr = $stderr
  original_stdout = $stdout

  # Redirect stderr and stdout
  output = $stderr = $stdout = StringIO.new

  yield

  # Return output
  output.string
ensure
  $stderr = original_stderr
  $stdout = original_stdout
end

# Runs a generated migration file the way ActiveRecord's migrator does: the
# class name comes from the file name, not from the class the file declares.
def run_migration_file(file, direction)
  version, name = File.basename(file).match(ActiveRecord::Migration::MigrationFilenameRegexp).captures
  ActiveRecord::MigrationProxy.new(name.camelize, version.to_i, file, nil).migrate(direction)
end
