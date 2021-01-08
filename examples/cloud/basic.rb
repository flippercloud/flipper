# Usage (from the repo root):
# env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/basic.rb
require 'pathname'
require 'logger'
root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper/cloud'
flipper = Flipper::Cloud.new

flipper[:stats].enable

if flipper[:stats].enabled?
  puts 'Enabled!'
else
  puts 'Disabled!'
end

flipper[:stats].disable

if flipper[:stats].enabled?
  puts 'Enabled!'
else
  puts 'Disabled!'
end
