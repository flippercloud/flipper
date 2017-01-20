require 'net/http'
require 'json'

module Flipper
  module Api
    module Client
      MIME_TYPE = 'application/json'

      def initialize(path_to_mount)
        @path = path_to_mount
      end

      def features(key)
      end
    end
  end
end
