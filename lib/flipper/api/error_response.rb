module Flipper
  module Api
    module ErrorResponse
      class Error
        attr_reader :http_status

        def initialize(code, message, info, http_status)
          @code = code
          @message = message
          @more_info = info
          @http_status = http_status
        end

        def as_json
          {
            code: @code,
            message: @message,
            more_info: @more_info,
          }
        end
      end

      ERRORS = {
        feature_not_found: Error.new(1, "Feature not found.", "", 404),
        group_not_registered: Error.new(2, "Group not registered.", "", 404),
      }
    end
  end
end
