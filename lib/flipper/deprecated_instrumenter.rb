module Flipper
  # Private: Deprecation warnings for instrumenter option
  module DeprecatedInstrumenter
    def deprecated_instrumenter_option options
      if options.has_key?(:instrumenter)
        warn "The `:instrumenter` option is deprecated and has no effect. Set `Flipper.instrumenter` globally."
        warn caller[1]
      end
    end

    def instrumenter
      warn "`#instrumenter` is deprecated. Use `Flipper.instrument` or `Flipper.instrumenter` instead."
      warn caller[0]

      Flipper.instrumenter
    end
  end
end
