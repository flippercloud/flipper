require 'active_support/lazy_load_hooks'
require 'flipper/adapters/active_record'

ActiveSupport.on_load(:active_record) do
  require 'flipper/adapters/active_record/models'
end
