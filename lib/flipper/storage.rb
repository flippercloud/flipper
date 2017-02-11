require "json"
require "forwardable"
require "flipper/adapter"
require "flipper/adapters/memoizable"
require "flipper/adapters/v2/memoizable"

module Flipper
  class Storage
    extend Forwardable

    attr_reader :adapter

    def_delegators :@adapter, :memoize=, :memoizing?, :cache

    def initialize(adapter)
      @adapter = case adapter.version
      when Adapter::V1
        Adapters::Memoizable.new(adapter)
      when Adapter::V2
        Adapters::V2::Memoizable.new(adapter)
      end
    end

    def features
      case @adapter.version
      when Adapter::V1
        @adapter.features
      when Adapter::V2
        v2_features
      end
    end

    def add(feature)
      case @adapter.version
      when Adapter::V1
        @adapter.add(feature)
      when Adapter::V2
        set = v2_features
        unless set.include?(feature.key)
          set.add(feature.key)
          @adapter.set("features", JSON.generate(set.to_a))
        end
      end
    end

    def remove(feature)
      case @adapter.version
      when Adapter::V1
        @adapter.remove(feature)
      when Adapter::V2
        set = v2_features
        if set.include?(feature.key)
          set.delete(feature.key)
          @adapter.set("features", JSON.generate(set.to_a))
          @adapter.del("feature/#{feature.key}")
        end
      end
    end

    def get(feature)
      case @adapter.version
      when Adapter::V1
        @adapter.get(feature)
      when Adapter::V2
        if raw = @adapter.get("feature/#{feature.key}")
          hash = JSON.parse(raw)
          symbolized_hash = {}
          hash.each_key do |key|
            symbolized_hash[key.to_sym] = hash[key]
          end
          symbolized_hash[:groups] = Set.new(symbolized_hash[:groups].map(&:to_sym))
          symbolized_hash[:actors] = Set.new(symbolized_hash[:actors])
          symbolized_hash
        else
          default_gate_values
        end
      end
    end

    def get_multi(features)
      case @adapter.version
      when Adapter::V1
        @adapter.get_multi(features)
      when Adapter::V2
        result = {}
        features.each do |feature|
          result[feature.key] = get(feature)
        end
        result
      end
    end

    def enable(feature, gate, thing)
      case @adapter.version
      when Adapter::V1
        add(feature)
        @adapter.enable feature, gate, thing
      when Adapter::V2
        add(feature)
        hash = get(feature)
        case gate.data_type
        when :boolean, :integer
          hash[gate.key] = thing.value
        when :set
          hash[gate.key].add(thing.value)
        end
        hash[:groups] = hash[:groups].to_a
        hash[:actors] = hash[:actors].to_a
        @adapter.set("feature/#{feature.key}", JSON.generate(hash))
        true
      end
    end

    def disable(feature, gate, thing)
      case @adapter.version
      when Adapter::V1
        add(feature)
        if gate.is_a?(Gates::Boolean)
          @adapter.clear feature
        else
          @adapter.disable feature, gate, thing
        end
      when Adapter::V2
        add(feature)
        hash = get(feature)
        case gate.data_type
        when :boolean
          hash = default_gate_values
        when :integer
          hash[gate.key] = thing.value
        when :set
          hash[gate.key].delete(thing.value)
        end
        hash[:groups] = hash[:groups].to_a
        hash[:actors] = hash[:actors].to_a
        @adapter.set("feature/#{feature.key}", JSON.generate(hash))
        true
      end
    end

    private

    def default_gate_values
      {
        :boolean => nil,
        :groups => Set.new,
        :actors => Set.new,
        :percentage_of_actors => nil,
        :percentage_of_time => nil,
      }
    end

    def v2_features
      if raw = @adapter.get("features")
        Set.new(JSON.parse(raw))
      else
        Set.new
      end
    end
  end
end
