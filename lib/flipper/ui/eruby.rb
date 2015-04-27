require 'erubis'

module Flipper
  module UI
    # Version of erubis just for flipper.
    class Eruby < ::Erubis::Eruby
      # switches '<%= ... %>' to escaped and '<%== ... %>' to unescaped.
      include ::Erubis::EscapeEnhancer
    end
  end
end
