module Flipper
  module Api
    module ErrorResponse
      class Error
        attr_reader :http_status

        def initialize(code, message, http_status)
          @code = code
          @message = message
          @more_info =
            'https://flippercloud.io/docs/api#error-code-reference'
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
        feature_not_found: Error.new(1, 'Feature not found.', 404),
        group_not_registered: Error.new(2, 'Group not registered.', 404),
        percentage_invalid:
          Error.new(3, 'Percentage must be a positive number less than or equal to 100.', 422),
        flipper_id_invalid: Error.new(4, 'Required parameter flipper_id is missing.', 422),
        name_invalid: Error.new(5, 'Required parameter name is missing.', 422),
      }.freeze
    end
  end
end
