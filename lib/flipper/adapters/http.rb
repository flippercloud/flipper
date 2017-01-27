require 'net/http'
require 'json'
require 'set'

module Flipper
  module Adapters
    # class for handling http requests.
    # Initialize with headers / basic_auth and use intance to make any requests
    # headers and basic_auth will be sent in every request
    # Request.new({ "X-Header" => "value" }, { "auth_username" => "auth_password" })
    class Request
      DEFAULT_HEADERS = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
      }.freeze

      def initialize(headers, basic_auth)
        @headers = DEFAULT_HEADERS.merge(headers.to_h)
        @basic_auth_username, @basic_auth_password = basic_auth.to_h.first
      end

      # Public: GET http request
      def get(path)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri, @headers)
        request.basic_auth(@basic_auth_username, @basic_auth_password) if basic_auth?
        http.request(request)
      end

      # Public: POST http request
      def post(path, data)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.request_uri, @headers)
        request.body = data.to_json
        request.basic_auth(@basic_auth_username, @basic_auth_password) if basic_auth?
        http.request(request)
      end

      # Public: DELETE http request
      def delete(path, data = {})
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Delete.new(uri.request_uri, @headers)
        request.body = data.to_h.to_json
        request.basic_auth(@basic_auth_username, @basic_auth_password) if basic_auth?
        http.request(request)
      end

      def basic_auth?
        @basic_auth_username && @basic_auth_password
      end
    end

    class Configuration
      attr_accessor :headers, :basic_auth
    end

    # Flipper API HTTP Adapter
    # Flipper::Adapters::Http.new('http://www.app.com/mount-point')
    class Http
      include Flipper::Adapter
      FEATURE_NOT_FOUND = 1

      attr_reader :name

      class << self
        attr_accessor :configuration
      end

      # Public: initialize with api url
      # http://www.myapp.com/api-mount-point
      def initialize(path_to_mount)
        configuration = self.class.configuration || Configuration.new
        @request = Request.new(configuration.headers, configuration.basic_auth)
        @path = path_to_mount
        @name = :http
      end

      def self.configure
        self.configuration ||= Configuration.new
        yield(configuration)
      end

      # Public: Get one feature
      # feature - Feature instance
      def get(feature)
        response = @request.get(@path + "/api/v1/features/#{feature.key}")
        parsed_response = JSON.parse(response.body)
        if parsed_response['code'] == FEATURE_NOT_FOUND
          default_feature_value
        else
          parsed_response['gates'].each_with_object({}) do |gate, feature_result|
            key = gate['key'].to_sym
            feature_result[key] = result_for_feature(gate['key'], gate['value'])
          end
        end
      end

      # Public: Add a feature
      # feature - Feature instance
      def add(feature)
        response = @request.post(@path + '/api/v1/features', name: feature.key)
        response.is_a?(Net::HTTPOK)
      end

      def get_multi(features)
        # could be cool to add this feature as an api endpoint requesting multiple features
        # or alternatively use a persistent connection and send multiple requests
      end

      # Public: Get all features
      def features
        response = @request.get(@path + '/api/v1/features')
        parsed_response = JSON.parse(response.body)
        parsed_response['features'].map { |feature| feature['key'] }.to_set
      end

      # Public: Remove a feature
      def remove(feature)
        response = @request.delete(@path + "/api/v1/features/#{feature.key}")
        response.is_a?(Net::HTTPNoContent)
      end

      # Public: Enable gate thing for feature
      def enable(feature, gate, thing)
        body = gate_request_body(gate.key, thing.value.to_s)
        response = @request.post(@path + "/api/v1/features/#{feature.key}/#{gate.key}", body)
        response.is_a?(Net::HTTPOK)
      end

      # Public: Disable gate thing for feature
      def disable(feature, gate, thing)
        body = delete_request_body(gate.key, thing.value)
        response = @request.delete(@path + "/api/v1/features/#{feature.key}/#{gate.key}", body)
        response.is_a?(Net::HTTPOK)
      end

      # Public: Clear all gate values for feature
      def clear(feature)
        response = @request.delete(@path + "/api/v1/features/#{feature.key}/boolean")
        response.is_a?(Net::HTTPOK)
      end

      private

      # Returns request body for enabling/disabling gate
      # gate_request_body(:percentage_of_actors, 10)
      # => { 'percentage' => 10 }
      def gate_request_body(key, value)
        case key.to_sym
        when :boolean
          {}
        when :groups
          { name: value }
        when :actors
          { flipper_id: value }
        when :percentage_of_actors, :percentage_of_time
          { percentage: value }
        else
          raise "#{key} is not a valid flipper gate key"
        end
      end

      def delete_request_body(key, value)
        return unless gates_with_delete_request_body.include?(key)
        gate_request_body(key, value)
      end

      def result_for_feature(key, value)
        case key.to_sym
        when :boolean
          value == true || nil
        when :groups, :actors
          value.to_set
        when :percentage_of_actors, :percentage_of_time
          value.zero? ? nil : value
        end
      end

      def default_feature_value
        {
          boolean: nil,
          groups: Set.new,
          actors: Set.new,
          percentage_of_actors: nil,
          percentage_of_time: nil,
        }
      end

      def gates_with_delete_request_body
        %i(groups actors)
      end
    end
  end
end
