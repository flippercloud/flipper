require 'helper'
require 'flipper/adapters/v2/redis'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::Redis do
  subject { described_class.new(DataStores.redis) }

  before do
    DataStores.reset_redis
  end

  it_should_behave_like 'a v2 flipper adapter'
end
