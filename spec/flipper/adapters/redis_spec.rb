require 'helper'
require 'flipper/adapters/redis'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Redis do
  subject { described_class.new(DataStores.redis) }

  before do
    DataStores.reset_redis
  end

  it_should_behave_like 'a flipper adapter'
end
