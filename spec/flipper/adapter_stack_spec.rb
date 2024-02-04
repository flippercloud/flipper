require 'flipper/adapters/failover'

RSpec.describe Flipper::AdapterStack do
  it 'returns single adapter' do
    adapter = Flipper::Adapters::Memory.new
    expect(described_class.new(adapter).to_a).to eq([adapter])
  end

  it 'returns nested adapters' do
    d = Flipper::Adapters::Memory.new
    c = Flipper::Adapters::Memoizable.new(d)
    b = Flipper::Adapters::Memory.new
    a = Flipper::Adapters::Failover.new(b, c)

    stack = described_class.new(a)
    expect(stack.to_a.size).to eq(4)
    expect(stack.to_a).to eq([a, b, c, d])
  end

  describe '#find' do
    let(:adapter) { Flipper::Adapters::Memory.new }
    subject { Flipper::AdapterStack.new(adapter) }

    it 'returns adapter that matches block' do
      expect(subject.find { |a| a == adapter }).to be(adapter)
    end

    it 'returns adapter that matches block' do
      expect(subject.find { false }).to be(nil)
    end

    it 'returns adapter matching given class name' do
      expect(subject.find(Flipper::Adapters::Memory)).to be(adapter)
    end

    it 'returns adapter matching given class name' do
      expect(subject.find(Flipper::Adapters::Strict)).to be(nil)
    end
  end
end
