require 'helper'
require 'flipper/adapters/memory'
require 'flipper/adapters/dalli'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Dalli do
  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:adapter) { Flipper::Adapters::Dalli.new(memory_adapter, DataStores.dalli) }
  let(:flipper) { Flipper.new(adapter) }

  subject { described_class.new(adapter, DataStores.dalli) }

  before do
    DataStores.reset_dalli
  end

  it_should_behave_like 'a flipper adapter'

  describe "#name" do
    it "is dalli" do
      expect(subject.name).to be(:dalli)
    end
  end
end
