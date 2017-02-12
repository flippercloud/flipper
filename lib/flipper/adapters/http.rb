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

      attr_reader :name

      def initialize(options = {})
        @options = options
        @client = Client.new(options)
        @uri = options.fetch(:uri).to_s
        @name = :http
      end

      def get(feature)
        response = @client.get(@uri + "/features/#{feature.key}")
        raise Error, response unless response.is_a?(Net::HTTPOK)

        parsed_response = JSON.parse(response.body)
        result_for_feature(feature, parsed_response.fetch('gates'))
      end

      def add(feature)
        response = @client.post(@uri + '/features', name: feature.key)
        response.is_a?(Net::HTTPOK)
      end

      def get_multi(features)
        csv_keys = features.map(&:key).join(',')
        response = @client.get(@uri + "/features?keys=#{csv_keys}")
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
        response = @client.get(@uri + '/features')
        raise Error, response unless response.is_a?(Net::HTTPOK)

        parsed_response = JSON.parse(response.body)
        parsed_response['features'].map { |feature| feature['key'] }.to_set
      end

      def remove(feature)
        response = @client.delete(@uri + "/features/#{feature.key}")
        response.is_a?(Net::HTTPNoContent)
      end

      def enable(feature, gate, thing)
        body = gate_request_body(gate.key, thing.value.to_s)
        response = @client.post(@uri + "/features/#{feature.key}/#{gate.key}", body)
        response.is_a?(Net::HTTPOK)
      end

      def disable(feature, gate, thing)
        body = gate_request_body(gate.key, thing.value)
        response = @client.delete(@uri + "/features/#{feature.key}/#{gate.key}", body)
        response.is_a?(Net::HTTPOK)
      end

      def clear(feature)
        response = @client.delete(@uri + "/features/#{feature.key}/boolean")
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
