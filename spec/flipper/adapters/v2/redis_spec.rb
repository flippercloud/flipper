require 'helper'
require 'flipper/adapters/v2/redis'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::Redis do
  let(:client) { Redis.new }
  subject { described_class.new(client) }

  before do
    client.flushdb
  end

  it_should_behave_like 'a v2 flipper adapter'
end
