# frozen_string_literal: true

require 'helper'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Memory do
  subject { described_class.new }

  it_behaves_like 'a flipper adapter'
end
