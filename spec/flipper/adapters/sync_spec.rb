require 'helper'
require 'flipper/adapters/sync'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Sync do
  let(:local) { Flipper::Adapters::Memory.new }
  let(:remote) { Flipper::Adapters::Memory.new }

  subject do
    described_class.new(local, remote)
  end

  it_should_behave_like 'a flipper adapter'
end
