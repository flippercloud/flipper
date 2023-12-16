require 'climate_control'

RSpec.configure do |config|
  def with_env(options = {}, &block)
    ClimateControl.modify(options, &block)
  end
end
