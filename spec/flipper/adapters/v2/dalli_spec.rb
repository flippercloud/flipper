require 'helper'
require 'flipper/adapters/v2/memory'
require 'flipper/adapters/v2/dalli'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::Dalli do
  let(:memory_adapter) { Flipper::Adapters::V2::Memory.new }
  let(:adapter) { described_class.new(memory_adapter, DataStores.dalli) }
  let(:flipper) { Flipper.new(adapter) }

  subject { described_class.new(adapter, DataStores.dalli) }

  before do
    DataStores.reset_dalli
  end

  it_should_behave_like 'a v2 flipper adapter'

  describe "#name" do
    it "is dalli" do
      expect(subject.name).to be(:dalli)
    end
  end
end
