# frozen_string_literal: true

require 'activesupport/lazy_load_hooks'

ActiveSupport.on_load(:active_record) do
  require 'flipper/adapters/active_record'
end
