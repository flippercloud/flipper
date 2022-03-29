require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class DeniedActorsGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/denied_actors/?\Z}

        def get
          feature = flipper[feature_name]
          @feature = Decorators::Feature.new(feature)

          breadcrumb 'Home', '/'
          breadcrumb 'Features', '/features'
          breadcrumb @feature.key, "/features/#{@feature.key}"
          breadcrumb 'Deny Actor'

          view_response :deny_actor
        end

        def post
          feature = flipper[feature_name]
          value = params['value'].to_s.strip
          values = value.split(UI.configuration.actors_separator).map(&:strip).uniq

          if values.empty?
            error = "#{value.inspect} is not a valid actor value."
            redirect_to("/features/#{feature.key}/denied_actors?error=#{error}")
          end

          values.each do |value|
            actor = Flipper::Actor.new(value)

            case params['operation']
            when 'deny'
              feature.deny_actor actor
            when 'reinstate'
              feature.reinstate_actor actor
            end
          end

          redirect_to("/features/#{feature.key}")
        end
      end
    end
  end
end
