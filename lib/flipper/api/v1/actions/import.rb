require 'flipper/exporters/json/export'
require 'flipper/api/action'
require 'flipper/api/parameter_parsing'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Import < Api::Action
          route %r{\A/import/?\Z}

          def post
            content_encoding = request.env['HTTP_CONTENT_ENCODING'.freeze].to_s.strip.downcase
            unless content_encoding.empty? || content_encoding == 'identity'
              json_error_response(:import_invalid)
            end

            body = read_import_body
            export = build_import_export(body)
            flipper.import(export)
            json_response({}, 204)
          end

          private

          def read_import_body
            request.body.rewind if request.body.respond_to?(:rewind)
            max = Flipper::Exporters::Json::Export::MAX_BYTES
            body = ParameterParsing.read_bounded(request.body, max + 1)
            request.body.rewind if request.body.respond_to?(:rewind)
            json_error_response(:import_invalid) if body.bytesize > max
            body
          end

          def build_import_export(body)
            export = Flipper::Exporters::Json::Export.new(contents: body)
            # Materialize the source adapter before mutation so malformed JSON
            # and invalid export roots cannot fail partway through synchronization.
            export.adapter
            export
          rescue Flipper::Exporters::Json::InvalidError
            json_error_response(:import_invalid)
          end
        end
      end
    end
  end
end
