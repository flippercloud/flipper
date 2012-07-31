require 'helper'
require 'flipper/adapters/redis'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Memory do
  let(:client) { Redis.new }

  subject { Flipper::Adapters::Redis.new(client) }

  before do
    client.flushdb
  end

  def read_key(key)
    client.get key
  rescue RuntimeError => e
    if e.message =~ /wrong kind of value/
      client.smembers(key).map { |member| member.to_i }.to_set
    else
      raise
    end
  end

  def write_key(key, value)
    case value
    when Array, Set
      value.each do |member|
        client.sadd key, member
      end
    else
      client.set key, value
    end
  end

  it_should_behave_like 'a flipper adapter'
end
