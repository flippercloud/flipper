module Flipper
  # Public: A point-in-time view of all feature gate data and its source version.
  #
  # When version is present, it must describe the exact feature data returned in
  # this snapshot. Adapters that cannot provide that guarantee should return nil.
  class Snapshot
    attr_reader :features, :version, :metadata

    def initialize(features:, version: nil, metadata: {})
      if !version.nil? && (!version.is_a?(Integer) || version < 0)
        raise ArgumentError, "snapshot version must be a nonnegative integer or nil"
      end
      @features = features
      @version = version
      @metadata = metadata.freeze
      freeze
    end
  end
end
