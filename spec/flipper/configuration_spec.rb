require 'helper'
require 'flipper/configuration'

RSpec.describe Flipper::Configuration do
  describe '#default' do
    it 'returns instance using Memory adapter' do
      expect(subject.default).to be_a(Flipper::DSL)
      # All adapter are wrapped in Memoizable
      expect(subject.default.adapter.adapter).to be_a(Flipper::Adapters::Memory)
    end

    it 'can be set default' do
      instance = Flipper.new(Flipper::Adapters::Memory.new)
      expect(subject.default).not_to be(instance)
      subject.default { instance }
      expect(subject.default).to be(instance)
    end
  end
end
