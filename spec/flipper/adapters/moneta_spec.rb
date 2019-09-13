require 'helper'
require 'flipper/adapters/moneta'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Moneta do
  let(:moneta) { Moneta.new(:Memory) }
  subject { described_class.new(moneta) }

  it_should_behave_like 'a flipper adapter'
end
