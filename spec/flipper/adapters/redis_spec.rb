require 'helper'
require 'flipper/adapters/redis'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Redis do
  let(:client) {
    options = {}

    if ENV['BOXEN_REDIS_URL']
      options[:url] = ENV['BOXEN_REDIS_URL']
    end

    Redis.new(options)
  }

  subject { described_class.new(client) }

  before do
    client.flushdb
  end

  it_should_behave_like 'a flipper adapter'
end
