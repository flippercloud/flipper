require "json"

module Flipper
  module Adapters
    class Http
      class Error < StandardError
        attr_reader :response

        def initialize(response)
          @response = response
          message = "Failed with status: #{response.code}"

          begin
            data = Typecast.from_json(response.body)

            if error_message = data["message"]
              message << "\n\n#{data["message"]}"
            end

            if more_info = data["more_info"]
              message << "\n#{data["more_info"]}"
            end
          rescue
            # welp we tried
          end

          super(message)
        end
      end
    end
  end
end
