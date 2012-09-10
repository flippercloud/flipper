require 'helper'
require 'flipper/adapters/memory'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Memory do
  let(:source) { {} }

  subject { described_class.new(source) }

  def read_key(key)
    source[key.to_s]
  end

  def write_key(key, value)
    source[key.to_s] = value
  end

  it_should_behave_like 'a flipper adapter'
end
