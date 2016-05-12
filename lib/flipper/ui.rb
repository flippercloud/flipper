require 'pathname'
require 'rack'
begin
  # Rack 2
  require 'rack/method_override'
rescue LoadError
  require 'rack/methodoverride'
end
require 'rack/protection'

require 'flipper'
require 'flipper/middleware/memoizer'

require 'flipper/ui/actor'
require 'flipper/ui/middleware'

module Flipper
  module UI
    class << self
      # Public: If you set this, the UI will always have a first breadcrumb that
      # says "App" which points to this href. The href can be a path (ie: "/")
      # or full url ("https://app.example.com/").
      attr_accessor :application_breadcrumb_href
      #Public: If set, then the add_feature button will be removed
      attr_accessor :remove_add_feature_button
    end

    def self.root
      @root ||= Pathname(__FILE__).dirname.expand_path.join('ui')
    end

    def self.app(flipper, options = {})
      app = lambda { |env| [200, {'Content-Type' => 'text/html'}, ['']] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Rack::Protection
      builder.use Rack::Protection::AuthenticityToken
      builder.use Rack::MethodOverride
      builder.use Flipper::Middleware::Memoizer, flipper
      builder.use Middleware, flipper
      builder.run app
      builder
    end
  end
end
