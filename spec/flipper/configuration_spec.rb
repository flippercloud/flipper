require 'helper'
require 'flipper/configuration'

RSpec.describe Flipper::Configuration do
  describe '#default_instance' do
    it 'defaults to new DSL instance' do
      expect(subject.default_instance).to be_instance_of(Flipper::DSL)
    end

    it 'can be overriden using default' do
      instance = Flipper.new(Flipper::Adapters::Memory.new)
      subject.default { instance }
      expect(subject.default_instance).to be(instance)
    end
  end
end
