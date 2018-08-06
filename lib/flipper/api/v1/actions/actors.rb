require 'flipper/api/action'
require 'flipper/api/v1/decorators/actor'

module Flipper
  module Api
    module V1
      module Actions
        class Actors < Api::Action
          route %r{\A/actors/(?<flipper_id>.*)/?\Z}

          def get
            keys = params['keys']
            features = if keys
                         names = keys.split(',')
                         if names.empty?
                           []
                         else
                           existing_feature_names = names.keep_if do |feature_name|
                             feature_exists?(feature_name)
                           end

                           flipper.preload(existing_feature_names)
                         end
                       else
                         flipper.features
                       end

            actor = Flipper::Actor.new(flipper_id)
            decorated_actor = Decorators::Actor.new(actor, features)
            json_response(decorated_actor.as_json)
          end

          private

          def feature_exists?(feature_name)
            flipper.features.map(&:key).include?(feature_name)
          end

          def flipper_id
            match = request.path_info.match(self.class.route_regex)
            match ? match[:flipper_id] : nil
          end
        end
      end
    end
  end
end
