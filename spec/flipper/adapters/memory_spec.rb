require 'helper'
require 'flipper/adapters/memory'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Memory do
  subject { described_class.new }

  it_should_behave_like 'a flipper adapter'
end
