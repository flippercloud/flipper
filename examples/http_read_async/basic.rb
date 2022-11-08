# Usage (from the repo root):
# env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/http_read_async/basic.rb
require 'bundler/setup'
require 'flipper/adapters/http_read_async'

# Configure flipper to use this adapter
Flipper.configure do |config|
  config.adapter do
    # something to start with
    adapter = Flipper::Adapters::Memory.new
    flipper = Flipper.new(adapter)
    flipper.enable(:stats)

    # configure the http read async adapter
    Flipper::Adapters::HttpReadAsync.new({
      url: "https://www.flippercloud.io/adapter",
      read_timeout: 2,
      open_timeout: 2,
      headers: {
        "Flipper-Cloud-Token" => ENV["FLIPPER_CLOUD_TOKEN"],
      },
      worker: {interval: 5},
      start_with: adapter,
    })
  end
end

# Check every second to see if the feature is enabled
loop do
  sleep 1

  if Flipper[:stats].enabled?
    puts "#{Time.now.to_i} Enabled!"
  else
    puts "#{Time.now.to_i} Disabled!"
  end
end
