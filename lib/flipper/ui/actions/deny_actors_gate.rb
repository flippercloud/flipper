require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class DenyActorsGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/deny_actors/?\Z}

        def post
          render_read_only if read_only?

          feature = flipper[feature_name]
          value = params['value'].to_s.strip
          values = value.split(UI.configuration.actors_separator).map(&:strip).uniq

          if values.empty?
            error = "#{value.inspect} is not a valid actor value."
            redirect_to("/features/#{Flipper::UI::Util.escape feature.key}/deny_actors?error=#{Flipper::UI::Util.escape error}")
          end

          values.each do |value|
            actor = Flipper::Actor.new(value)

            case params['operation']
            when 'deny'
              feature.deny_actor actor
            when 'permit'
              feature.permit_actor actor
            end
          end

          redirect_to("/features/#{Flipper::UI::Util.escape feature.key}")
        end
      end
    end
  end
end
