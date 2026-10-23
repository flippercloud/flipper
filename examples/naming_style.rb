require 'bundler/setup'
require 'flipper'
require 'flipper/adapters/naming_style'

Flipper.configure do |config|
  config.use Flipper::Adapters::NamingStyle, :snake # or :camel, :kebab, :screaming_snake, or a Regexp
end

# This will work because the feature key is in snake_case.
Flipper.enable(:snake_case)

begin
  # This will raise an error because the feature key is in CamelCase.
  Flipper.enable(:CamelCase)
rescue Flipper::Adapters::NamingStyle::InvalidFormat => e
  puts "#{e.class}: #{e.message}"
else
  fail "An error should have been raised, but wasn't."
end
