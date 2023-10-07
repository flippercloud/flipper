require 'flipper/cloud/telemetry'

RSpec.describe Flipper::Cloud::Telemetry do
  describe '#increment' do
    it 'works' do
      telemetry = described_class.new
      telemetry.track_feature(:foo, true)
      telemetry.track_feature(:foo, true)
      telemetry.track_feature(:foo, false)
      telemetry.track_feature(:bar, false)
      telemetry.track_feature(:bar, false)
      telemetry.track_feature(:bar, false)

      expect(telemetry.storage[:foo].values.map(&:values).flatten.map(&:value)).to eq([2, 1])
      expect(telemetry.storage[:bar].values.map(&:values).flatten.map(&:value)).to eq([3])
    end
  end
end
