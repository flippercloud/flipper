require 'rails/generators/active_record'

module Flipper
  module Generators
    class SetupGenerator < ::Rails::Generators::Base
      desc 'Peform any necessary steps to install Flipper'

      def perform
        if defined?(Flipper::Adapters::ActiveRecord)
          invoke 'flipper:active_record'
        end
      end
    end
  end
end
