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
        raw = @adapter.get("feature/#{feature.key}")
        if raw
          data = JSON.parse(raw)
          hash = {}
          data.each_key do |key|
            hash[key.to_sym] = data[key]
          end
          hash[:groups] = Set.new(hash[:groups])
          hash[:actors] = Set.new(hash[:actors])
          hash
        else
          @adapter.default_config
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

    def get_all
      case @adapter.version
      when Adapter::V1
        @adapter.get_all
      when Adapter::V2
        set = v2_features
        get_multi(set)
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
          hash[gate.key] = thing.value.to_s
        when :set
          hash[gate.key].add(thing.value.to_s)
        end
        hash[:groups] = hash[:groups].to_a.map(&:to_s)
        hash[:actors] = hash[:actors].to_a.map(&:to_s)
        @adapter.set("feature/#{feature.key}", JSON.generate(hash))
        true
      end
    end

    def disable(feature, gate, thing)
      case @adapter.version
      when Adapter::V1
        disable_v1(feature, gate, thing)
      when Adapter::V2
        disable_v2(feature, gate, thing)
      end
    end

    def clear(feature)
      case @adapter.version
      when Adapter::V1
        @adapter.clear(feature)
      when Adapter::V2
        hash = get(feature)
        @adapter.default_config.each { |key, value| hash[key] = value }
        @adapter.set("feature/#{feature.key}", JSON.generate(hash))
        true
      end
    end

    def import(source_storage)
      @adapter.import(source_storage.adapter)
    end

    private

    def disable_v1(feature, gate, thing)
      add(feature)
      @adapter.disable feature, gate, thing
      # if gate.is_a?(Gates::Boolean)
      #   @adapter.clear feature
      # else
      # end
    end

    def disable_v2(feature, gate, thing)
      add(feature)
      hash = get(feature)
      case gate.data_type
      when :boolean
        hash = @adapter.default_config
      when :integer
        hash[gate.key] = thing.value.to_s
      when :set
        hash[gate.key].delete(thing.value.to_s)
      end
      hash[:groups] = hash[:groups].to_a.map(&:to_s)
      hash[:actors] = hash[:actors].to_a.map(&:to_s)
      @adapter.set("feature/#{feature.key}", JSON.generate(hash))
      true
    end

    def v2_features
      raw = @adapter.get("features")
      if raw
        Set.new(JSON.parse(raw))
      else
        Set.new
      end
    end
  end
end
