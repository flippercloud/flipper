require 'flipper/identifier'

RSpec.describe Flipper::Identifier do
  describe '#flipper_id' do
    it 'uses class name and id' do
      class BlahBlah < Struct.new(:id)
        include Flipper::Identifier
      end
      expect(BlahBlah.new(5).flipper_id).to eq('BlahBlah;5')
    end
  end
end
