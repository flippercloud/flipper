require 'rack'
require 'flipper/ui/action_collection'

# Require all actions automatically.
Pathname(__FILE__).dirname.join('actions').each_child(false) do |name|
  require "flipper/ui/actions/#{name}"
end

module Flipper
  module UI
    class Middleware
      # Public: Initializes an instance of the UI middleware.
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
      #   use Flipper::UI::Middleware, flipper
      #
      #   # using with a block that yields a flipper instance
      #   use Flipper::UI::Middleware, lambda { Flipper.new(...) }
      #
      def initialize(app, flipper_or_block)
        @app = app

        if flipper_or_block.respond_to?(:call)
          @flipper_block = flipper_or_block
        else
          @flipper = flipper_or_block
        end

        @action_collection = ActionCollection.new

        # UI
        @action_collection.add UI::Actions::Features
        @action_collection.add UI::Actions::AddFeature
        @action_collection.add UI::Actions::Feature
        @action_collection.add UI::Actions::ActorsGate
        @action_collection.add UI::Actions::GroupsGate
        @action_collection.add UI::Actions::BooleanGate
        @action_collection.add UI::Actions::PercentageOfTimeGate
        @action_collection.add UI::Actions::PercentageOfActorsGate
        @action_collection.add UI::Actions::Gate

        # Static Assets/Files
        @action_collection.add UI::Actions::File

        # Catch all redirect to features
        @action_collection.add UI::Actions::Home
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
          @app.call(env)
        else
          action_class.run(flipper, request)
        end
      end
    end
  end
end
