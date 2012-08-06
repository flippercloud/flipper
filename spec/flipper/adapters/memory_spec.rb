require 'helper'
require 'flipper/adapters/memory'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Memory do
  let(:source) { {} }

  subject { described_class.new(source) }

  def read_key(key)
    source[key]
  end

  def write_key(key, value)
    source[key] = value
  end

  it_should_behave_like 'a flipper adapter'
end
