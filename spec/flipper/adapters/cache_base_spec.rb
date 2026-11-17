require 'flipper/adapters/cache_base'
require 'flipper/adapters/read_only'

RSpec.describe Flipper::Adapters::CacheBase do
  describe '#read_only?' do
    it 'preserves the read-only status of the underlying adapter' do
      adapter = Flipper::Adapters::ReadOnly.new(Flipper::Adapters::Memory.new)
      cached = described_class.new(adapter, Object.new)

      expect(Flipper.new(cached).read_only?).to be(true)
    end

    it 'keeps writable adapters writable' do
      cached = described_class.new(Flipper::Adapters::Memory.new, Object.new)

      expect(Flipper.new(cached).read_only?).to be(false)
    end
  end
end
