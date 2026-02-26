require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class BlockActorsGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/block_actors/?\Z}

        def post
          render_read_only if read_only?

          feature = flipper[feature_name]
          value = params['value'].to_s.strip
          values = value.split(UI.configuration.actors_separator).map(&:strip).uniq

          if values.empty?
            error = "#{value.inspect} is not a valid actor value."
            redirect_to("/features/#{Flipper::UI::Util.escape feature.key}/block_actors?error=#{Flipper::UI::Util.escape error}")
          end

          values.each do |value|
            actor = Flipper::Actor.new(value)

            case params['operation']
            when 'block'
              feature.block_actor actor
            when 'unblock'
              feature.unblock_actor actor
            end
          end

          redirect_to("/features/#{Flipper::UI::Util.escape feature.key}")
        end
      end
    end
  end
end
