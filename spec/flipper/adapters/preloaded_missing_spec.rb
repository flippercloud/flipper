require 'flipper/adapters/memoizable'
require 'flipper/adapters/operation_logger'

RSpec.describe 'Missing features after preloading' do
  let(:source) { Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new) }
  let(:flipper) { Flipper.new(source) }

  before do
    flipper.enable(:known)
    flipper.memoize = true
    flipper.preload_all
    source.reset
  end

  it 'serves unknown feature checks from the complete snapshot' do
    expect(flipper.enabled?(:missing)).to be(false)
    expect(flipper.enabled?(:another)).to be(false)
    expect(source.count(:get)).to eq(0)
  end

  it 'serves unknown feature preloads from the complete snapshot' do
    features = flipper.preload([:missing, :another])
    expect(features.map(&:enabled?)).to eq([false, false])
    expect(source.count(:get_multi)).to eq(0)
    expect(source.count(:get)).to eq(0)
  end

  it 'still reads flags changed locally after preloading' do
    flipper.enable(:missing)
    expect(flipper.enabled?(:missing)).to be(true)
    flipper[:known].clear
    expect(flipper.enabled?(:known)).to be(false)
  end
end
