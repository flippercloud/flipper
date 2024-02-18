require 'flipper/exporters/json/export'
require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Import < Api::Action
          route %r{\A/import/?\Z}

          def post
            # Rack 3 changed the requirement to rewind the body, so we can't assume it is rewound,
            # so rewind before under Rack 3+ and after under Rack 2.
            request.body.rewind if Gem::Version.new(Rack.release) >= Gem::Version.new('3.0.0')
            body = request.body.read
            request.body.rewind if Gem::Version.new(Rack.release) < Gem::Version.new('3.0.0')
            export = Flipper::Exporters::Json::Export.new(contents: body)
            flipper.import(export)
            json_response({}, 204)
          rescue Flipper::Exporters::Json::InvalidError
            json_error_response(:import_invalid)
          end
        end
      end
    end
  end
end
