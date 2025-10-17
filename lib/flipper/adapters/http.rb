require 'net/http'
require 'json'
require 'set'
require 'flipper'
require 'flipper/adapters/http/error'
require 'flipper/adapters/http/client'

module Flipper
  module Adapters
    class Http
      include Flipper::Adapter

      attr_reader :client, :last_get_all_response

      def initialize(options = {})
        @client = Client.new(url: options.fetch(:url),
                             headers: options[:headers],
                             basic_auth_username: options[:basic_auth_username],
                             basic_auth_password: options[:basic_auth_password],
                             read_timeout: options[:read_timeout],
                             open_timeout: options[:open_timeout],
                             write_timeout: options[:write_timeout],
                             max_retries: options[:max_retries],
                             debug_output: options[:debug_output])
        @last_get_all_etag = nil
        @last_get_all_result = nil
      end

      def get(feature)
        response = @client.get("/features/#{feature.key}")
        if response.is_a?(Net::HTTPOK)
          parsed_response = Typecast.from_json(response.body)
          result_for_feature(feature, parsed_response.fetch('gates'))
        elsif response.is_a?(Net::HTTPNotFound)
          default_config
        else
          raise Error, response
        end
      end

      def get_multi(features)
        csv_keys = features.map(&:key).join(',')
        response = @client.get("/features?keys=#{csv_keys}&exclude_gate_names=true")
        raise Error, response unless response.is_a?(Net::HTTPOK)

        parsed_response = Typecast.from_json(response.body)
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

      def get_all(cache_bust: false)
        path = "/features?exclude_gate_names=true"
        path += "&_cb=#{Time.now.to_i}" if cache_bust

        # Pass If-None-Match header if we have an ETag
        options = {}
        if @last_get_all_etag
          options[:headers] = { if_none_match: @last_get_all_etag }
        end

        response = @client.get(path, options)

        @last_get_all_response = response

        if response.is_a?(Net::HTTPNotModified)
          if @last_get_all_result
            return @last_get_all_result
          else
            raise Error, response
          end
        end

        raise Error, response unless response.is_a?(Net::HTTPOK)

        @last_get_all_etag = response['etag'] if response['etag']

        parsed_response = response.body.empty? ? {} : Typecast.from_json(response.body)
        parsed_features = parsed_response['features'] || []
        gates_by_key = parsed_features.each_with_object({}) do |parsed_feature, hash|
          hash[parsed_feature['key']] = parsed_feature['gates']
          hash
        end

        result = {}
        gates_by_key.each_key do |key|
          feature = Feature.new(key, self)
          result[feature.key] = result_for_feature(feature, gates_by_key[feature.key])
        end

        # Cache the result for 304 responses
        @last_get_all_result = result
        result
      end

      def features
        response = @client.get('/features?exclude_gate_names=true')
        raise Error, response unless response.is_a?(Net::HTTPOK)

        parsed_response = Typecast.from_json(response.body)
        parsed_response['features'].map { |feature| feature['key'] }.to_set
      end

      def add(feature)
        body = JSON.generate(name: feature.key)
        response = @client.post('/features', body)
        raise Error, response unless response.is_a?(Net::HTTPOK)
        true
      end

      def remove(feature)
        response = @client.delete("/features/#{feature.key}")
        raise Error, response unless response.is_a?(Net::HTTPNoContent)
        true
      end

      def enable(feature, gate, thing)
        body = request_body_for_gate(gate, thing.value)
        query_string = gate.key == :groups ? "?allow_unregistered_groups=true" : ""
        response = @client.post("/features/#{feature.key}/#{gate.key}#{query_string}", body)
        raise Error, response unless response.is_a?(Net::HTTPOK)
        true
      end

      def disable(feature, gate, thing)
        body = request_body_for_gate(gate, thing.value)
        query_string = gate.key == :groups ? "?allow_unregistered_groups=true" : ""
        response = case gate.key
        when :percentage_of_actors, :percentage_of_time
          @client.post("/features/#{feature.key}/#{gate.key}#{query_string}", body)
        else
          @client.delete("/features/#{feature.key}/#{gate.key}#{query_string}", body)
        end
        raise Error, response unless response.is_a?(Net::HTTPOK)
        true
      end

      def clear(feature)
        response = @client.delete("/features/#{feature.key}/clear")
        raise Error, response unless response.is_a?(Net::HTTPNoContent)
        true
      end

      def import(source)
        adapter = self.class.from(source)
        export = adapter.export(format: :json, version: 1)
        response = @client.post("/import", export.contents)
        raise Error, response unless response.is_a?(Net::HTTPNoContent)
        true
      end

      private

      def request_body_for_gate(gate, value)
        data = case gate.key
        when :boolean
          {}
        when :groups
          { name: value.to_s }
        when :actors
          { flipper_id: value.to_s }
        when :percentage_of_actors, :percentage_of_time
          { percentage: value.to_s }
        when :expression
          value
        else
          raise "#{gate.key} is not a valid flipper gate key"
        end
        JSON.generate(data)
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
        when :json
          value
        when :set
          value ? value.to_set : Set.new
        else
          unsupported_data_type gate.data_type
        end
      end

      private

      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end
    end
  end
end
