require 'flipper/api/action'
require 'flipper/api/v1/decorators/actor'

module Flipper
  module Api
    module V1
      module Actions
        class Actors < Api::Action
          route %r{\A/actors/(?<flipper_id>.*)/?\Z}

          def get
            actor = Flipper::Actor.new(flipper_id)
            keys = string_param('keys')
            features = if keys
                         names = keys.split(',')
                         if names.empty?
                           []
                         else
                           flipper.preload(names)
                         end
                       else
                         flipper.features
                       end

            decorated_actor = Decorators::Actor.new(actor, features)
            json_response(decorated_actor.as_json)
          end

          private

          # Decodes %XX escapes so "User%3B1" means "User;1". Uses path
          # decoding rather than form decoding so a "+" stays a "+", as in
          # "user+tag@example.com".
          def flipper_id
            match = request.path_info.match(self.class.route_regex)
            return unless match

            value = Rack::Utils.unescape_path(match[:flipper_id]).force_encoding(Encoding::UTF_8)
            json_error_response(:request_invalid) unless value.valid_encoding?
            value
          end
        end
      end
    end
  end
end
