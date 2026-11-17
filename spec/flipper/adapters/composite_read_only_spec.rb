require 'flipper/adapters/dual_write'
require 'flipper/adapters/failover'
require 'flipper/adapters/read_only'

RSpec.describe 'Composite adapter read-only status' do
  def memory
    Flipper::Adapters::Memory.new
  end

  def read_only
    Flipper::Adapters::ReadOnly.new(memory)
  end

  it 'keeps a writable dual-write stack writable' do
    expect(Flipper::Adapters::DualWrite.new(memory, memory).read_only?).to be(false)
  end

  it 'reports a read-only local dual-write adapter' do
    expect(Flipper::Adapters::DualWrite.new(read_only, memory).read_only?).to be(true)
  end

  it 'reports a read-only remote dual-write adapter' do
    expect(Flipper::Adapters::DualWrite.new(memory, read_only).read_only?).to be(true)
  end

  it 'reports a read-only failover primary even with a writable secondary' do
    expect(Flipper::Adapters::Failover.new(read_only, memory).read_only?).to be(true)
  end

  it 'keeps a writable failover primary writable when the secondary only serves reads' do
    expect(Flipper::Adapters::Failover.new(memory, read_only).read_only?).to be(false)
  end

  it 'reports a read-only secondary when failover dual writes are enabled' do
    adapter = Flipper::Adapters::Failover.new(memory, read_only, dual_write: true)
    expect(adapter.read_only?).to be(true)
  end
end
