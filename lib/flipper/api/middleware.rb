require 'rack'
require 'flipper/api/action_collection'

# Require all V1 actions automatically.
Pathname(__FILE__).dirname.join('v1/actions').each_child(false) do |name|
  require "flipper/api/v1/actions/#{name}"
end

module Flipper
  module Api
    class Middleware
      def initialize(app, options = {})
        @app = app
        @env_key = options.fetch(:env_key, 'flipper')

        @action_collection = ActionCollection.new
        @action_collection.add Api::V1::Actions::PercentageOfTimeGate
        @action_collection.add Api::V1::Actions::PercentageOfActorsGate
        @action_collection.add Api::V1::Actions::ActorsGate
        @action_collection.add Api::V1::Actions::GroupsGate
        @action_collection.add Api::V1::Actions::BooleanGate
        @action_collection.add Api::V1::Actions::ClearFeature
        @action_collection.add Api::V1::Actions::Actors
        @action_collection.add Api::V1::Actions::Feature
        @action_collection.add Api::V1::Actions::Features
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        request = Rack::Request.new(env)
        action_class = @action_collection.action_for_request(request)

        if action_class.nil?
          @app.call(env)
        else
          flipper = env.fetch(@env_key) { Flipper }
          action_class.run(flipper, request)
        end
      end
    end
  end
end
