module Flipper
  module UI
    # All flipper ui errors inherit from this.
    Error = Class.new(StandardError)

    # No longer raised: actions answer 405 for request methods they don't
    # handle. Kept so code that rescues it still loads.
    RequestMethodNotSupported = Class.new(Error)
  end
end
