require 'active_support'
require 'flipper/instrumentation/bugsnag'

# test double for Bugsnag
class Bugsnag
  def self.clear_feature_flag(feature_name)
  end

  def self.add_feature_flag(feature_name)
  end
end

RSpec.describe Flipper::Instrumentation::Bugsnag do
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter, instrumenter: ActiveSupport::Notifications) }

  context 'feature enabled checks' do
    it 'clears disabled features' do
      expect(Bugsnag).to receive(:clear_feature_flag).with(:search)
      flipper.enabled? :search
    end

    it 'adds enabled features' do
      flipper.enable :search
      expect(Bugsnag).to receive(:add_feature_flag).with(:search)
      flipper.enabled? :search
    end
  end
end
