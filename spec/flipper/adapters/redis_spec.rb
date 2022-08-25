require 'flipper/adapters/redis'

RSpec.describe Flipper::Adapters::Redis do
  let(:client) do
    options = {}

    options[:url] = ENV['REDIS_URL'] if ENV['REDIS_URL']

    Redis.raise_deprecations = true
    Redis.new(options)
  end

  subject { described_class.new(client) }

  before do
    begin
      client.flushdb
    rescue Redis::CannotConnectError
      ENV['CI'] ? raise : skip('Redis not available')
    end
  end

  it_should_behave_like 'a flipper adapter'

  it 'configures itself on load' do
    Flipper.configuration = nil
    Flipper.instance = nil

    silence { load 'flipper/adapters/redis.rb' }

    expect(Flipper.adapter.adapter).to be_a(Flipper::Adapters::Redis)
  end
end
