require 'pathname'
require 'rack'
require 'rack/methodoverride'
require 'rack/protection'

require 'flipper'
require 'flipper/middleware/memoizer'

require 'flipper/ui/actor'
require 'flipper/ui/middleware'

module Flipper
  module UI
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
