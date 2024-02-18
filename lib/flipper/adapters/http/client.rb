require 'uri'
require 'openssl'
require 'flipper/version'

module Flipper
  module Adapters
    class Http
      class Client
        DEFAULT_HEADERS = {
          'content-type' => 'application/json',
          'accept' => 'application/json',
          'user-agent' => "Flipper HTTP Adapter v#{VERSION}",
        }.freeze

        HTTPS_SCHEME = "https".freeze

        CLIENT_FRAMEWORKS = {
          rails:    -> { Rails.version if defined?(Rails) },
          sinatra:  -> { Sinatra::VERSION if defined?(Sinatra) },
          hanami:   -> { Hanami::VERSION if defined?(Hanami) },
          sidekiq:  -> { Sidekiq::VERSION if defined?(Sidekiq) },
          good_job: -> { GoodJob::VERSION if defined?(GoodJob) },
        }

        attr_reader :uri, :headers
        attr_reader :basic_auth_username, :basic_auth_password
        attr_reader :read_timeout, :open_timeout, :write_timeout
        attr_reader :max_retries, :debug_output

        def initialize(options = {})
          @uri = URI(options.fetch(:url))
          @basic_auth_username = options[:basic_auth_username]
          @basic_auth_password = options[:basic_auth_password]
          @read_timeout = options[:read_timeout]
          @open_timeout = options[:open_timeout]
          @write_timeout = options[:write_timeout]
          @max_retries = options.key?(:max_retries) ? options[:max_retries] : 0
          @debug_output = options[:debug_output]

          @headers = {}
          DEFAULT_HEADERS.each { |key, value| add_header key, value }
          if options[:headers]
            options[:headers].each { |key, value| add_header key, value }
          end
        end

        def add_header(key, value)
          key = key.to_s.downcase.gsub('_'.freeze, '-'.freeze).freeze
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
            'client-language' => "ruby",
            'client-language-version' => "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})",
            'client-platform' => RUBY_PLATFORM,
            'client-engine' => defined?(RUBY_ENGINE) ? RUBY_ENGINE : "",
            'client-pid' => Process.pid.to_s,
            'client-thread' => Thread.current.object_id.to_s,
            'client-hostname' => Socket.gethostname,
          }.merge(headers)

          body = options[:body]
          request = http_method.new(uri.request_uri)
          request.initialize_http_header(request_headers)

          client_frameworks.each do |framework, version|
            request.add_field("client-framework", [framework, version].join("="))
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
