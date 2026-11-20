require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'
require 'flipper/adapters/actor_limit'

module Flipper
  module UI
    module Actions
      class ActorsGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/actors/?\Z}

        def get
          feature = flipper[feature_name]
          @feature = Decorators::Feature.new(feature)
          view_response :add_actor
        end

        def post
          render_read_only if read_only?

          feature = flipper[feature_name]
          value = params['value'].to_s.strip
          # The Remove button posts one enabled actor, whose id may contain the
          # separator (e.g. "OrderItem;[1, 2]" from a composite primary key).
          values = if params['operation'] == 'disable' && feature.actors_value.include?(value)
            [value]
          else
            value.split(UI.configuration.actors_separator).map(&:strip).uniq
          end

          if values.empty?
            redirect_to_form(feature, "#{value.inspect} is not a valid actor value.")
          end

          values.each do |value|
            actor = Flipper::Actor.new(value)

            case params['operation']
            when 'enable'
              feature.enable_actor actor
            when 'disable'
              feature.disable_actor actor
            end
          end

          redirect_to("/features/#{Flipper::UI::Util.escape feature.key}")
        rescue Flipper::Adapters::ActorLimit::LimitExceeded => exception
          redirect_to_form(feature, exception.message)
        end

        private

        def redirect_to_form(feature, error)
          redirect_to("/features/#{Flipper::UI::Util.escape feature.key}/actors?error=#{Flipper::UI::Util.escape error}")
        end
      end
    end
  end
end
