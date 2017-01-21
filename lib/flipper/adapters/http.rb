require 'net/http'
require 'json'

module Flipper
  module Adapters
    # class for handling http requests.
    # Initialize with headers / basic_auth and use intance to make any requests
    # headers and basic_auth will be sent in every request

    class  Request
      DEFAULT_HEADERS = { 'Content-Type' => 'application/json',
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
        request.basic_auth *@basic_auth if @basic_auth
        response = http.request(request)
      end

      def post(path, data)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.request_uri, @headers)
        request.body = data.to_json
        request.basic_auth *@basic_auth if @basic_auth
        response = http.request(request)
      end

      def delete(path)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Delete.new(uri.request_uri, @headers)
        request.basic_auth *@basic_auth if @basic_auth
        response = http.request(request)
      end
    end

    class Configuration
      attr_accessor :headers, :basic_auth
    end

    class Http
      include Flipper::Adapter

      attr_reader :name

      class << self
        attr_accessor :configuration
      end

      def initialize(path_to_mount)
        configuration = self.class.configuration
        @request = Request.new(configuration.headers, configuration.basic_auth)
        @path = path_to_mount
        @name = :http
      end

      def self.configure
        self.configuration ||= Configuration.new
        yield(configuration)
      end

      # Get one feature
      def get(feature)
        #response = get_request(@path + "/api/v1/features/#{feature}")
        response = @request.get(@path + "/api/v1/features/#{feature}")
        parsed_response = JSON.parse(response.body)
        parsed_response['gates'].reduce({}) do |acc, gate|
          key = gate['key'].to_sym
          acc[key] = gate['value'].is_a?(Array) ? gate['value'].to_set : gate['value']
          acc
        end
      end

      # Add a feature
      def add(feature)
        response = @request.post(@path + '/api/v1/features', name: feature)
        response.is_a?(Net::HTTPOK)
      end

      def get_multi(features)
        # could be cool to add this feature as an api endpoint requesting multiple features
        # or alternatively use a persistent connection and send multiple requests
      end

      # Get all features
      def features
        response = @request.get(@path + '/api/v1/features')
        parsed_response = JSON.parse(response.body)
        parsed_response['features'].map { |feature| feature['key'] }.to_set
      end

      # Remove a feature
      def remove(feature)
        response = @request.delete(@path + "/api/v1/features/#{feature}")
        response.is_a?(Net::HTTPOK)
      end

      # Enable gate thing for feature
      def enable(feature, gate, thing)
        body = gate_request_body(gate.key, thing.value.to_s)
        response = @request.post(@path + "/api/v1/features/#{feature.key}/#{gate.key}", body)
        response.is_a?(Net::HTTPOK)
      end

      # Disable gate thing for feature
      def disable(feature, gate, _thing)
        response = @request.delete(@path + "/api/v1/features/#{feature.key}/#{gate.key}")
        response.is_a?(Net::HTTPOK)
      end

      private

      # Returns request body for enabling/disabling a gate
      # i.e gate_request_body(:percentage_of_actors, 10)
      # returns { 'percentage' => 10 }
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
          raise "#{key} is not a valid flipper gate name"
        end
      end
    end
  end
end
