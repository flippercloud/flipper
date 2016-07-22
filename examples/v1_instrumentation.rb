require File.expand_path('../example_setup', __FILE__)

require 'securerandom'
require 'active_support/notifications'

class FlipperSubscriber
  def call(*args)
    event = ActiveSupport::Notifications::Event.new(*args)
    puts event.inspect
  end

  ActiveSupport::Notifications.subscribe(/flipper/, new)
end

require 'flipper'
require 'flipper/adapters/v2/memory'
require 'flipper/adapters/v2/instrumented'

# pick an adapter
adapter = Flipper::Adapters::V2::Memory.new

# instrument it if you want, if not you still get the feature instrumentation
instrumented = Flipper::Adapters::V2::Instrumented.new(adapter, :instrumenter => ActiveSupport::Notifications)

# get a handy dsl instance
flipper = Flipper.new(instrumented, :instrumenter => ActiveSupport::Notifications)

# grab a feature
search = flipper[:search]

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
