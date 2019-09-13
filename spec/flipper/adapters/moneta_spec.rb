# frozen_string_literal: true

require 'helper'
require 'flipper/adapters/moneta'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Moneta do
  subject { described_class.new(moneta) }

  let(:moneta) { Moneta.new(:Memory) }

  it_behaves_like 'a flipper adapter'
end
