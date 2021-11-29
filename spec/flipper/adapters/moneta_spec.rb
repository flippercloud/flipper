require 'flipper/adapters/moneta'

RSpec.describe Flipper::Adapters::Moneta do
  let(:moneta) { Moneta.new(:Memory) }
  subject { described_class.new(moneta) }

  it_should_behave_like 'a flipper adapter'
end
