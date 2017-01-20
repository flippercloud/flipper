require 'net/http'
require 'json'

module Flipper
  module Adapters
    # Module for handling http requests.
    # Any class that needs to make an http request can include/use this
    module Request
      HEADERS = { 'Content-Type' => 'application/json' }.freeze

      def get_request(path)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri, HEADERS)
        response = http.request(request)
      end

      def post_request(path, data)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.request_uri, HEADERS)
        request.body = data.to_json
        response = http.request(request)
      end

      def delete_request(path)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Delete.new(uri.request_uri, HEADERS)
        response = http.request(request)
      end
    end

    # allow user to configure client
    # Http.configure { |c| c.headers = {} }
    #
    class Configuration
      attr_accessor :headers, :basic_auth
    end

    class Http
      include Flipper::Adapter
      include Request
      attr_reader :name

      class << self
        attr_accessor :configuration
      end

      def initialize(path_to_mount)
        @configuration = self.class.configuration
        @path = path_to_mount
        @name = :http
      end

      def self.configure
        self.configuration ||= Configuration.new
        yield(configuration)
      end

      # Get one feature
      def get(feature)
        response = get_request(@path + "/api/v1/features/#{feature}")
        parsed_response = JSON.parse(response.body)
        parsed_response['gates'].reduce({}) do |acc, gate|
          key = gate['key'].to_sym
          acc[key] = gate['value'].is_a?(Array) ? gate['value'].to_set : gate['value']
          acc
        end
      end

      # Add a feature
      def add(feature)
        response = post_request(@path + '/api/v1/features', name: feature)
        true
      end

      def get_multi(features)
        # could be cool to add this feature as an api endpoint requesting multiple features
        # or alternatively use a persistent connection and request multiple endpoints
      end

      # Get all features
      def features
        response = get_request(@path + '/api/v1/features')
        parsed_response = JSON.parse(response.body)
        parsed_response['features'].map { |feature| feature['key'] }.to_set
      end

      # Remove a feature
      def remove(feature)
        response = delete_request(@path + "/api/v1/features/#{feature}")
        true
        # JSON.parse(response.body)
      end

      # Enable gate thing for feature
      def enable(feature, gate, thing)
        body = gate_request_body(gate.key, thing.value.to_s)
        response = post_request(@path + "/api/v1/features/#{feature.key}/#{gate.key}", body)
        true
      end

      # Disable gate thing for feature
      def disable(feature, gate, _thing)
        response = delete_request(@path + "/api/v1/features/#{feature.key}/#{gate.key}")
        true
      end

      private

      # Returns request body for enabling/disabling a gate
      # i.e gate_request_body(:percentage_of_actors, 10)
      # returns { 'percentage' => 10 }
      def gate_request_body(gate_key, value)
        parameter = gate_parameter(gate_key)
        { parameter.to_s => value }
      end

      def gate_parameter(gate_name)
        case gate_name.to_sym
        when :groups
          :name
        when :actors
          :flipper_id
        when :percentage_of_actors
          :percentage
        when :percentage_of_time
          :percentage
        else
          raise "#{gate_name} is not a valid flipper gate name"
        end
      end
    end
  end
end
