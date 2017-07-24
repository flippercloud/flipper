require 'helper'
require 'flipper/configuration'

RSpec.describe Flipper::Configuration do
  describe '#default_instance' do
    it 'raises if default not configured' do
      expect { subject.default_instance }.to raise_error(Flipper::DefaultNotSet)
    end

    it 'can be set using default' do
      instance = Flipper.new(Flipper::Adapters::Memory.new)
      subject.default { instance }
      expect(subject.default_instance).to be(instance)
    end
  end
end
