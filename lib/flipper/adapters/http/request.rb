require 'json'

module Flipper
  module Adapters
    class Http
      # class for handling http requests.
      # Initialize with Configuration instance
      # Configuration attributes will be sent in every request
      class Request
        DEFAULT_HEADERS = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
        }.freeze

        def initialize(options = {})
          @headers = DEFAULT_HEADERS.merge(options[:headers] || {})
          @basic_auth_username = options[:basic_auth_username]
          @basic_auth_password = options[:basic_auth_password]
          @read_timeout = options[:read_timeout]
          @open_timeout = options[:open_timeout]
        end

        # Public: GET http request
        def get(path)
          uri = URI.parse(path)
          http = net_http(uri)
          request = Net::HTTP::Get.new(uri.request_uri, @headers)
          request.basic_auth(@basic_auth_username, @basic_auth_password) if basic_auth?
          http.request(request)
        end

        # Public: POST http request
        def post(path, data)
          uri = URI.parse(path)
          http = net_http(uri)
          request = Net::HTTP::Post.new(uri.request_uri, @headers)
          request.body = JSON.generate(data)
          request.basic_auth(@basic_auth_username, @basic_auth_password) if basic_auth?
          http.request(request)
        end

        # Public: DELETE http request
        def delete(path, data = {})
          uri = URI.parse(path)
          http = net_http(uri)
          request = Net::HTTP::Delete.new(uri.request_uri, @headers)
          request.body = JSON.generate(data.to_h)
          request.basic_auth(@basic_auth_username, @basic_auth_password) if basic_auth?
          http.request(request)
        end

        private

        def basic_auth?
          @basic_auth_username && @basic_auth_password
        end

        def net_http(uri)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = @read_timeout if @read_timeout
          http.open_timeout = @open_timeout if @open_timeout
          http
        end
      end
    end
  end
end
