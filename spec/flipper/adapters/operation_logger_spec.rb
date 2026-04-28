require 'flipper/adapters/operation_logger'

RSpec.describe Flipper::Adapters::OperationLogger do
  let(:operations) { [] }
  let(:adapter)    { Flipper::Adapters::Memory.new }
  let(:flipper)    { Flipper.new(adapter) }

  subject { described_class.new(adapter, operations) }

  it_should_behave_like 'a flipper adapter'

  it 'shows itself when inspect' do
    subject.features
    output = subject.inspect
    expect(output).to match(/OperationLogger/)
    expect(output).to match(/operation_logger/)
    expect(output).to match(/@type=:features/)
    expect(output).to match(/@adapter=#<Flipper::Adapters::Memory/)
  end

  describe '#get' do
    before do
      @feature = flipper[:stats]
      @result = subject.get(@feature)
    end

    it 'logs operation' do
      expect(subject.count(:get)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.get(@feature))
    end
  end

  describe '#enable' do
    before do
      @feature = flipper[:stats]
      @gate = @feature.gate(:boolean)
      @thing = Flipper::Types::Boolean.new
      @result = subject.enable(@feature, @gate, @thing)
    end

    it 'logs operation' do
      expect(subject.count(:enable)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.enable(@feature, @gate, @thing))
    end
  end

  describe '#disable' do
    before do
      @feature = flipper[:stats]
      @gate = @feature.gate(:boolean)
      @thing = Flipper::Types::Boolean.new
      @result = subject.disable(@feature, @gate, @thing)
    end

    it 'logs operation' do
      expect(subject.count(:disable)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.disable(@feature, @gate, @thing))
    end
  end

  describe '#features' do
    before do
      flipper[:stats].enable
      @result = subject.features
    end

    it 'logs operation' do
      expect(subject.count(:features)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.features)
    end
  end

  describe '#add' do
    before do
      @feature = flipper[:stats]
      @result = subject.add(@feature)
    end

    it 'logs operation' do
      expect(subject.count(:add)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.add(@feature))
    end
  end

  describe '#import' do
    before do
      @source = Flipper::Adapters::Memory.new
      @result = subject.import(@source)
    end

    it 'logs operation' do
      expect(subject.count(:import)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.import(@source))
    end
  end

  describe '#export' do
    before do
      @result = subject.export(format: :json, version: 1)
    end

    it 'logs operation' do
      expect(subject.count(:export)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.export(format: :json, version: 1))
    end
  end

  describe '#read_integer' do
    it 'forwards to wrapped adapter and logs operation' do
      adapter.set_integer_if_greater(:sync_version, 42)
      result = subject.read_integer(:sync_version)

      expect(result).to eq(42)
      expect(subject.count(:read_integer)).to be(1)
    end
  end

  describe '#set_integer_if_greater' do
    it 'forwards to wrapped adapter and logs operation' do
      result = subject.set_integer_if_greater(:sync_version, 100)

      expect(result).to eq(true)
      expect(adapter.read_integer(:sync_version)).to eq(100)
      expect(subject.count(:set_integer_if_greater)).to be(1)
    end
  end
end
