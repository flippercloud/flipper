require 'json'

module Flipper
  module Adapters
    class Http
      class Client
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

        def get(url)
          perform Net::HTTP::Get, url, @headers
        end

        def post(url, data = {})
          perform Net::HTTP::Post, url, @headers, body: JSON.generate(data)
        end

        def delete(url, data = {})
          perform Net::HTTP::Delete, url, @headers, body: JSON.generate(data)
        end

        private

        def perform(http_method, url, headers = {}, options = {})
          uri = URI.parse(url)
          http = build_http(uri)
          request = http_method.new(uri.request_uri, headers)

          body = options[:body]
          request.body = body if body

          if @basic_auth_username && @basic_auth_password
            request.basic_auth(@basic_auth_username, @basic_auth_password)
          end

          http.request(request)
        end

        def build_http(uri)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = @read_timeout if @read_timeout
          http.open_timeout = @open_timeout if @open_timeout
          http
        end
      end
    end
  end
end
