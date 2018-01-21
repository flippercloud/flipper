require 'pathname'
require 'logger'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'redis'
require 'rollout'
require 'flipper'
require 'flipper/adapters/rollout'

redis = Redis.new
rollout = Rollout.new(redis)
rollout.activate(:stats)

adapter = Flipper::Adapters::Rollout.new(rollout)
flipper = Flipper.new(adapter)

if flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end

rollout.deactivate(:stats)

if flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end
