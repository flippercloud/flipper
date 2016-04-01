require 'rack'
require 'flipper'

require 'rack/methodoverride'
require 'rack/protection'
require 'flipper/api/middleware'

module Flipper
  module Api
    class << self
    end
    
    def self.app(flipper)
      app = lambda { |env| [200, {'Content-Type' => 'application/json'}, ['']] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Flipper::Api::Middleware, flipper
      builder.run app
      builder
    end
  end
end
