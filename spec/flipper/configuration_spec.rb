require 'helper'
require 'flipper/configuration'

RSpec.describe Flipper::Configuration do
  describe '#default' do
    it 'raises if default not configured' do
      expect { subject.default }.to raise_error(Flipper::DefaultNotSet)
    end

    it 'can be set default' do
      instance = Flipper.new(Flipper::Adapters::Memory.new)
      subject.default { instance }
      expect(subject.default).to be(instance)
    end
  end
end
