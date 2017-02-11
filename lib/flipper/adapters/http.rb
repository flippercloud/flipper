require 'net/http'
require 'json'
require 'set'

module Flipper
  module Adapters
    # class for handling http requests.
    # Initialize with Configuration instance
    # Configuration attributes will be sent in every request
    class Request
      DEFAULT_HEADERS = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
      }.freeze

      def initialize(configuration)
        @headers = DEFAULT_HEADERS.merge(configuration.headers.to_h)
        @basic_auth_username, @basic_auth_password = configuration.basic_auth.to_h.first
        @read_timeout = configuration.read_timeout
        @open_timeout = configuration.open_timeout
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
        request.body = data.to_json
        request.basic_auth(@basic_auth_username, @basic_auth_password) if basic_auth?
        http.request(request)
      end

      # Public: DELETE http request
      def delete(path, data = {})
        uri = URI.parse(path)
        http = net_http(uri)
        request = Net::HTTP::Delete.new(uri.request_uri, @headers)
        request.body = data.to_h.to_json
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

    class Configuration
      attr_accessor :headers, :basic_auth, :read_timeout, :open_timeout
    end

    # Flipper API HTTP Adapter
    # uri = URI('http://www.app.com/mount-point')
    # Flipper::Adapters::Http.new(uri)
    class Http
      include Flipper::Adapter
      attr_reader :name

      class Error < StandardError
        attr_reader :response

        def initialize(response)
          @response = response
          super("Failed with status: #{response.code}")
        end
      end

      class << self
        attr_accessor :configuration
      end

      # Public: initialize with api url
      # http://www.myapp.com/api-mount-point
      def initialize(uri)
        configuration = self.class.configuration || Configuration.new
        @request = Request.new(configuration)
        @uri = uri.to_s
        @name = :http
      end

      def self.configure
        self.configuration ||= Configuration.new
        yield(configuration)
      end

      def get(feature)
        response = @request.get(@uri + "/features/#{feature.key}")
        raise Error, response unless response.is_a?(Net::HTTPOK)

        parsed_response = JSON.parse(response.body)
        result_for_feature(feature, parsed_response.fetch('gates'))
      end

      def add(feature)
        response = @request.post(@uri + '/features', name: feature.key)
        response.is_a?(Net::HTTPOK)
      end

      def get_multi(features)
        csv_keys = features.map(&:key).join(',')
        response = @request.get(@uri + "/features?keys=#{csv_keys}")
        raise Error, response unless response.is_a?(Net::HTTPOK)

        parsed_response = JSON.parse(response.body)
        parsed_features = parsed_response.fetch('features')
        gates_by_key = parsed_features.each_with_object({}) do |parsed_feature, hash|
          hash[parsed_feature['key']] = parsed_feature['gates']
          hash
        end

        result = {}
        features.each do |feature|
          result[feature.key] = result_for_feature(feature, gates_by_key[feature.key])
        end
        result
      end

      def features
        response = @request.get(@uri + '/features')
        raise Error, response unless response.is_a?(Net::HTTPOK)

        parsed_response = JSON.parse(response.body)
        parsed_response['features'].map { |feature| feature['key'] }.to_set
      end

      def remove(feature)
        response = @request.delete(@uri + "/features/#{feature.key}")
        response.is_a?(Net::HTTPNoContent)
      end

      def enable(feature, gate, thing)
        body = gate_request_body(gate.key, thing.value.to_s)
        response = @request.post(@uri + "/features/#{feature.key}/#{gate.key}", body)
        response.is_a?(Net::HTTPOK)
      end

      def disable(feature, gate, thing)
        body = gate_request_body(gate.key, thing.value)
        response = @request.delete(@uri + "/features/#{feature.key}/#{gate.key}", body)
        response.is_a?(Net::HTTPOK)
      end

      def clear(feature)
        response = @request.delete(@uri + "/features/#{feature.key}/boolean")
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

      def result_for_feature(feature, api_gates)
        api_gates ||= []
        result = default_config

        feature.gates.each do |gate|
          api_gate = api_gates.detect { |ag| ag['key'] == gate.key.to_s }
          result[gate.key] = value_for_gate(gate, api_gate) if api_gate
        end

        result
      end

      def value_for_gate(gate, api_gate)
        value = api_gate['value']
        case gate.data_type
        when :boolean, :integer
          value ? value.to_s : value
        when :set
          value ? value.to_set : Set.new
        else
          unsupported_data_type(gate.data_type)
        end
      end

      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end
    end
  end
end
