# frozen_string_literal: true

require 'helper'
require 'flipper/adapters/redis'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Redis do
  subject { described_class.new(client) }

  let(:client) do
    options = {}

    options[:url] = ENV['REDIS_URL'] if ENV['REDIS_URL']

    Redis.new(options)
  end

  before do
    client.flushdb
  end

  it_behaves_like 'a flipper adapter'
end
