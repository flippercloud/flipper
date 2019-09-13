require 'helper'

RSpec.describe Flipper::Instrumenters::Noop do
  describe '.instrument' do
    context 'with name' do
      it 'yields block' do
        yielded = false
        described_class.instrument(:foo) { yielded = true }
        expect(yielded).to eq(true)
      end
    end

    context 'with name and payload' do
      it 'yields block' do
        yielded = false
        described_class.instrument(:foo, pay: :load) { yielded = true }
        expect(yielded).to eq(true)
      end
    end
  end
end
