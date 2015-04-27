# Instrumentation

Flipper comes with automatic instrumentation. By default these work with ActiveSupport::Notifications, but only require the pieces of ActiveSupport that are needed and only do so if you actually attempt to require the instrumentation files listed below.

To use the log subscriber:

```ruby
# Gemfile
gem "activesupport"

# config/initializers/flipper.rb (or wherever you want it)
require "flipper/instrumentation/log_subscriber"
```

To use the statsd instrumentation:

```ruby
# Gemfile
gem "activesupport"
gem "statsd-ruby"

# config/initializers/flipper.rb (or wherever you want it)
require "flipper/instrumentation/statsd"
Flipper::Instrumentation::StatsdSubscriber.client = Statsd.new # or whatever your statsd instance is
```

You can also do whatever you want with the instrumented events. Check out [this example](https://github.com/jnunemaker/flipper/blob/master/examples/instrumentation.rb) for more.
