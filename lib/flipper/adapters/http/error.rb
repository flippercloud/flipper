module Flipper
  module Adapters
    class Http
      class Error < StandardError
        attr_reader :response

        def initialize(response)
          @response = response
          super("Failed with status: #{response.code} #{response.body}")
        end
      end
    end
  end
end
