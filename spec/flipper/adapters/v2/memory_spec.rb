require 'helper'
require 'flipper/adapters/v2/memory'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::Memory do
  subject { described_class.new }

  it_should_behave_like 'a v2 flipper adapter'
end
