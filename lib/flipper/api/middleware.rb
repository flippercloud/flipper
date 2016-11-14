require 'rack'
require 'flipper/api/action_collection'

# Require all V1 actions automatically.
Pathname(__FILE__).dirname.join('v1/actions').each_child(false) do |name|
  require "flipper/api/v1/actions/#{name}"
end

module Flipper
  module Api
    class Middleware
      # Public: Initializes an instance of the API middleware.
      #
      # app - The app this middleware is included in.
      # flipper_or_block - The Flipper::DSL instance or a block that yields a
      #                    Flipper::DSL instance to use for all operations.
      #
      # Examples
      #
      #   flipper = Flipper.new(...)
      #
      #   # using with a normal flipper instance
      #   use Flipper::Api::Middleware, flipper
      #
      #   # using with a block that yields a flipper instance
      #   use Flipper::Api::Middleware, lambda { Flipper.new(...) }
      #
      def initialize(app, flipper_or_block)
        @app = app

        if flipper_or_block.respond_to?(:call)
          @flipper_block = flipper_or_block
        else
          @flipper = flipper_or_block
        end

        @action_collection = ActionCollection.new
        @action_collection.add Api::V1::Actions::PercentageOfTimeGate
        @action_collection.add Api::V1::Actions::PercentageOfActorsGate
        @action_collection.add Api::V1::Actions::ActorsGate
        @action_collection.add Api::V1::Actions::GroupsGate
        @action_collection.add Api::V1::Actions::BooleanGate
        @action_collection.add Api::V1::Actions::Feature
        @action_collection.add Api::V1::Actions::Features
      end

      def flipper
        @flipper ||= @flipper_block.call
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        request = Rack::Request.new(env)
        action_class = @action_collection.action_for_request(request)
        if action_class.nil?
          @app.status = 404
          @app.call(env)
        else
          action_class.run(flipper, request)
        end
      end
    end
  end
end
