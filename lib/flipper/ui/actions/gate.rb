require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Gate < UI::Action
        route %r{features/[^/]*/[^/]*/?\Z}

        def post
          feature_name, gate_name = request.path.split('/').pop(2).map{ |value| Rack::Utils.unescape value }
          update_gate_method_name = "update_#{gate_name}"

          feature = flipper[feature_name.to_sym]
          @feature = Decorators::Feature.new(feature)

          if respond_to?(update_gate_method_name, true)
            send(update_gate_method_name, feature)
          else
            update_gate_method_undefined(gate_name)
          end

          redirect_to "/features/#{@feature.key}"
        end

        private

        # Private: Returns error response that gate update method is not defined.
        def update_gate_method_undefined(gate_name)
          error = Rack::Utils.escape("#{gate_name.inspect} gate does not exist therefore it cannot be updated.")
          redirect_to("/features/#{@feature.key}?error=#{error}")
        end
      end
    end
  end
end
