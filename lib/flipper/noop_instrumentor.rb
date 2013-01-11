module Flipper
  class NoopInstrumentor
    def self.instrument(name, payload = {})
      yield
    end
  end
end
