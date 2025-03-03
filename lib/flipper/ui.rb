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
      rack_protection_options = if options.key?(:rack_protection)
        options[:rack_protection]
      else
        {}
      end

      app = ->(_) { [200, { Rack::CONTENT_TYPE => 'text/html' }, ['']] }
      builder = Rack::Builder.new
      yield builder if block_given?

      # Only use Rack::Protection::AuthenticityToken if no other options are
      # provided. Should avoid some pain for some people. If any options are
      # provided then go whole hog and include all of Rack::Protection for
      # backwards compatibility.
      if rack_protection_options.empty?
        builder.use Rack::Protection::AuthenticityToken
      else
        builder.use Rack::Protection, rack_protection_options
      end

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
