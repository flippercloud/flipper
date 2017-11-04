require_relative "./ar_setup"

# Requires the flipper-active_record gem to be installed.
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
