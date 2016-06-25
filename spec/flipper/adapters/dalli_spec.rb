require 'helper'
require 'flipper/adapters/memory'
require 'flipper/adapters/dalli'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Dalli do
  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:cache)   { Dalli::Client.new('localhost:11211') }
  let(:adapter) { Flipper::Adapters::Dalli.new(memory_adapter, cache) }
  let(:flipper) { Flipper.new(adapter) }

  subject { described_class.new(adapter, cache) }

  before do
    cache.flush
  end

  it_should_behave_like 'a flipper adapter'

  describe "#name" do
    it "is instrumented" do
      expect(subject.name).to be(:dalli)
    end
  end
end
