require 'helper'
require 'flipper/adapters/memory'
require 'flipper/adapters/dalli'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Dalli do
  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:cache)   { Dalli::Client.new(ENV["BOXEN_MEMCACHED_URL"] || '127.0.0.1:11211') }
  let(:adapter) { Flipper::Adapters::Dalli.new(memory_adapter, cache) }
  let(:flipper) { Flipper.new(adapter) }

  subject { described_class.new(adapter, cache) }

  before do
    cache.flush
  end

  it_should_behave_like 'a flipper adapter'

  describe "#remove" do
    it "expires feature" do
      feature = flipper[:stats]
      adapter.get(feature)
      adapter.remove(feature)
      expect(cache.get(feature)).to be(nil)
    end
  end

  describe "#name" do
    it "is dalli" do
      expect(subject.name).to be(:dalli)
    end
  end
end
