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
require 'flipper/ui/middleware'
require 'flipper/ui/configuration'

module Flipper
  module UI
    def self.root
      @root ||= Pathname(__FILE__).dirname.expand_path.join('ui')
    end

    def self.app(flipper = nil, options = {})
      env_key = options.fetch(:env_key, 'flipper')

      if options.key?(:rack_protection)
        warn "[DEPRECATION] `rack_protection` option is deprecated. " +
          "Flipper::UI now only includes Rack::Protection::AuthenticityToken middleware. " +
          "If you need additional protection, you can add it yourself."
      end

      app = ->(_) { [200, { Rack::CONTENT_TYPE => 'text/html' }, ['']] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Rack::Protection::AuthenticityToken
      builder.use Rack::MethodOverride
      builder.use Flipper::Middleware::SetupEnv, flipper, env_key: env_key
      builder.use Flipper::UI::Middleware, flipper: flipper, env_key: env_key
      builder.run app
      klass = self
      app = builder.to_app
      app.define_singleton_method(:inspect) { klass.inspect } # pretty rake routes output
      app
    end

    # Public: yields configuration instance for customizing UI text
    def self.configure
      yield(configuration)
    end

    def self.configuration
      @configuration ||= ::Flipper::UI::Configuration.new
    end
  end
end
