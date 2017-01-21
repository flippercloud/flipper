require 'net/http'
require 'json'
require 'set'

module Flipper
  module Adapters
    # class for handling http requests.
    # Initialize with headers / basic_auth and use intance to make any requests
    # headers and basic_auth will be sent in every request
    class  Request
      DEFAULT_HEADERS = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
      }.freeze

      def initialize(headers, basic_auth)
        @headers = DEFAULT_HEADERS.merge(headers.to_h)
        @basic_auth = basic_auth.to_h.first
      end

      def get(path)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri, @headers)
        request.basic_auth(*@basic_auth) if @basic_auth
        http.request(request)
      end

      def post(path, data)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.request_uri, @headers)
        request.body = data.to_json
        request.basic_auth(*@basic_auth) if @basic_auth
        http.request(request)
      end

      def delete(path)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Delete.new(uri.request_uri, @headers)
        request.basic_auth(*@basic_auth) if @basic_auth
        http.request(request)
      end
    end

    class Configuration
      attr_accessor :headers, :basic_auth
    end

    # Flipper API HTTP Adapter
    # Flipper::Adapters::Http.new('http://www.app.com/mount-point')
    class Http
      include Flipper::Adapter

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
        parsed_response['gates'].reduce({}) do |acc, gate|
          key = gate['key'].to_sym
          acc[key] = gate['value'].is_a?(Array) ? gate['value'].to_set : gate['value']
          acc
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
        response.is_a?(Net::HTTPOK)
      end

      # Public: Enable gate thing for feature
      def enable(feature, gate, thing)
        body = gate_request_body(gate.key, thing.value.to_s)
        response = @request.post(@path + "/api/v1/features/#{feature.key}/#{gate.key}", body)
        response.is_a?(Net::HTTPOK)
      end

      # Public: Disable gate thing for feature
      def disable(feature, gate, _thing)
        response = @request.delete(@path + "/api/v1/features/#{feature.key}/#{gate.key}")
        response.is_a?(Net::HTTPOK)
      end

      private

      # Returns request body for enabling/disabling  gate
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
        when :percentage_of_actors
          { percentage: value }
        when :percentage_of_time
          { percentage: value }
        else
          raise "#{key} is not a valid flipper gate key"
        end
      end
    end
  end
end
