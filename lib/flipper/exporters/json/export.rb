require "flipper/export"
require "flipper/typecast"

module Flipper
  module Exporters
    module Json
      # Raised when the contents of the export are not valid.
      class InvalidError < StandardError; end
      class JsonError < InvalidError; end

      # Internal: JSON export class that knows how to build features hash
      # from data.
      class Export < ::Flipper::Export
        # The maximum size, in bytes, of an import payload. A legitimate export
        # is small: even 100k feature-heavy gates is only ~20 MB. Anything past
        # this ceiling is almost certainly abuse, so import endpoints reject it
        # before reading the whole body into memory.
        MAX_BYTES = 50 * 1024 * 1024

        def initialize(contents:, version: 1)
          super contents: contents, version: version, format: :json
        end

        # Public: The features hash identical to calling get_all on adapter.
        def features
          @features ||= begin
            features = Typecast.from_json(contents).fetch("features")
            Typecast.features_hash(features)
          rescue JSON::ParserError
            raise JsonError
          rescue
            raise InvalidError
          end
        end
      end
    end
  end
end
