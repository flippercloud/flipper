require 'uri'
require 'openssl'
require 'flipper/version'

module Flipper
  module Adapters
    class Http
      class Client
        DEFAULT_HEADERS = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'User-Agent' => "Flipper HTTP Adapter v#{VERSION}",
        }.freeze

        HTTPS_SCHEME = "https".freeze

        CLIENT_FRAMEWORKS = {
          rails: -> { Rails.version if defined?(Rails) },
          sinatra: -> { Sinatra::VERSION if defined?(Sinatra) },
          hanami: -> { Hanami::VERSION if defined?(Hanami) },
        }

        attr_reader :uri, :headers
        attr_reader :basic_auth_username, :basic_auth_password
        attr_reader :read_timeout, :open_timeout, :write_timeout, :max_retries, :debug_output

        def initialize(options = {})
          @uri = URI(options.fetch(:url))
          @headers = DEFAULT_HEADERS.merge(options[:headers] || {})
          @basic_auth_username = options[:basic_auth_username]
          @basic_auth_password = options[:basic_auth_password]
          @read_timeout = options[:read_timeout]
          @open_timeout = options[:open_timeout]
          @write_timeout = options[:write_timeout]
          @max_retries = options.key?(:max_retries) ? options[:max_retries] : 0
          @debug_output = options[:debug_output]
        end

        def add_header(key, value)
          @headers[key] = value
        end

        def get(path)
          perform Net::HTTP::Get, path, @headers
        end

        def post(path, body = nil)
          perform Net::HTTP::Post, path, @headers, body: body
        end

        def delete(path, body = nil)
          perform Net::HTTP::Delete, path, @headers, body: body
        end

        private

        def perform(http_method, path, headers = {}, options = {})
          uri = uri_for_path(path)
          http = build_http(uri)
          request = build_request(http_method, uri, headers, options)
          http.request(request)
        end

        def uri_for_path(path)
          uri = @uri.dup
          path_uri = URI(path)
          uri.path += path_uri.path
          uri.query = "#{uri.query}&#{path_uri.query}" if path_uri.query
          uri
        end

        def build_http(uri)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = @read_timeout if @read_timeout
          http.open_timeout = @open_timeout if @open_timeout
          http.max_retries = @max_retries if @max_retries
          http.write_timeout = @write_timeout if @write_timeout
          http.set_debug_output(@debug_output) if @debug_output

          if uri.scheme == HTTPS_SCHEME
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          end

          http
        end

        def build_request(http_method, uri, headers, options)
          request_headers = {
            client_language: "ruby",
            client_language_version: "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})",
            client_platform: RUBY_PLATFORM,
            client_engine: defined?(RUBY_ENGINE) ? RUBY_ENGINE : "",
            client_pid: Process.pid.to_s,
            client_thread: Thread.current.object_id.to_s,
            client_hostname: Socket.gethostname,
          }.merge(headers)

          body = options[:body]
          request = http_method.new(uri.request_uri)
          request.initialize_http_header(request_headers)

          client_frameworks.each do |framework, version|
            request.add_field("Client-Framework", [framework, version].join("="))
          end

          request.body = body if body

          if @basic_auth_username && @basic_auth_password
            request.basic_auth(@basic_auth_username, @basic_auth_password)
          end

          request
        end

        def client_frameworks
          CLIENT_FRAMEWORKS.transform_values { |detect| detect.call rescue nil }.compact
        end
      end
    end
  end
end
