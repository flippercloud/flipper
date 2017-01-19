require 'net/http'
require 'json'

module Flipper
  module Adapters
    class Http
      include  Flipper::Adapter

      HEADERS = {
        'Content-Type' =>  'application/json'
      }.freeze

      attr_reader :name

      def initialize(path_to_mount)
        @path = path_to_mount
        @name = :http
      end

      def get(feature)
        url = endpoint("/api/v1/features/#{feature}")
        res = http.get(url)
        JSON.parse(res.body)
      end

      def add(feature)
        uri = URI.parse(@path + '/api/v1/features')
        http = Net::HTTP.new(uri.host, uri.port)
        response = http.post(uri.path, {name: feature}.to_json, HEADERS)
        puts JSON.parse(response.body)
      end

      def get_multi(features)
        # could be cool to add this feature as an api endpoint requesting multiple features
        []
      end

      def features
        url = endpoint("/api/v1/features")
        res = http.get(url)
      end

      def remove(feature)
        url = endpoint("/api/v1/features/#{feature}")
        res = http.delete(url)
      end

      def enable(feature, gate, thing)
        url = endpoint("/api/v1/features/#{feature.key}/#{gate.key}")
        body = request_body(gate.key, thing.value.to_s)
        res = http.post(url, body)
      end

      def disable(feature, gate, thing)
        url = endpoint("/api/v1/features/#{feature.key}/#{gate.key}")
        res = http.delete(url)
      end

      private

      def http
       Net::HTTP.new(@path)
      end

      def request(url)
        uri = URI.parse(@path + url)
        Net::HTTP.new(uri)
      end

      def endpoint(url)
        "#{@path}#{url}"
      end

      def request_body(gate_key, value)
        parameter = gate_parameter(gate_key)
        {"#{parameter}" => value}.to_json
      end

      def gate_parameter(gate_name)
        case gate_name.to_sym
        when :groups
          :name
        when :actors
          :flipper_id
        when :percentage_of_actors
          :percentage
        when :percentage_of_timec
          :percentage
        else
          raise "#{gate_name} is not a valid gate name"}
        end
      end
    end
  end
end
