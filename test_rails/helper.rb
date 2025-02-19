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

  $stderr = original_stderr
  $stdout = original_stdout

  # Return output
  output.string
end
