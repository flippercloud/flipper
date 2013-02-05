require 'securerandom'
require 'active_support/notifications'
require 'flipper/instrumentation/metriks_subscriber'

ActiveSupport::Notifications.subscribe /\.flipper$/,
  Flipper::Instrumentation::MetriksSubscriber
