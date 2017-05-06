require 'helper'
require 'flipper/adapters/redis'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Redis do
  let(:client) do
    options = {}

    options[:url] = ENV['REDIS_URL'] if ENV['REDIS_URL']

    Redis.new(options)
  end

  subject { described_class.new(client) }

  before do
    client.flushdb
  end

  it_should_behave_like 'a flipper adapter'
end
