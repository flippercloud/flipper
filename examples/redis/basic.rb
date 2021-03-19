require 'bundler/setup'
require 'logger'

require 'flipper/adapters/redis'
options = {}
if ENV['REDIS_URL']
  options[:url] = ENV['REDIS_URL']
end
client = Redis.new(options)
adapter = Flipper::Adapters::Redis.new(client)
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
