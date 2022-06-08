require 'bundler/setup'
require 'securerandom'
require 'active_support'
require 'active_support/notifications'

class FlipperSubscriber
  def call(*args)
    event = ActiveSupport::Notifications::Event.new(*args)
    puts event.inspect
  end

  ActiveSupport::Notifications.subscribe(/flipper/, new)
end

require 'flipper'
require 'flipper/adapters/instrumented'

Flipper.configure do |config|
  config.instrumenter ActiveSupport::Notifications
  config.adapter { Flipper::Adapters::Instrumented.new(Flipper::Adapters::Memory.new) }
end

# grab a feature
search = Flipper[:search]

perform = lambda do
  # check if that feature is enabled
  if search.enabled?
    puts 'Search away!'
  else
    puts 'No search for you!'
  end
end

perform.call
puts 'Enabling Search...'
search.enable
perform.call
