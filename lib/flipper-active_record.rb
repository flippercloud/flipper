ActiveSupport.on_load(:active_record) do
  require 'flipper/adapters/active_record'
end
