require "flipper/railtie"

module Flipper
  module Cloud
    class Engine < Rails::Engine
      paths["config/routes.rb"] = ["lib/flipper/cloud/routes.rb"]
    end
  end
end
