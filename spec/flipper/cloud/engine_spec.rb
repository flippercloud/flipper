require 'helper'
require 'rails'
require 'flipper/cloud'

RSpec.describe Flipper::Cloud::Engine do
  let(:application) do
    Class.new(Rails::Application) do
      config.eager_load = false
      config.logger = ActiveSupport::Logger.new($stdout)
    end
  end

  before do
    Rails.application = nil
  end

  describe 'config' do
    describe 'cloud.sync_method' do
      it 'uses FLIPPER_CLOUD_SYNC_METHOD env variable' do
        ENV['FLIPPER_CLOUD_SYNC_METHOD'] = 'webhook'
        expect(application.config.flipper.cloud.sync_method).to eq(:webhook)
        ENV.delete('FLIPPER_CLOUD_SYNC_METHOD')
      end

      it 'defaults to :poll in development' do
        expect(application.config.flipper.cloud.sync_method).to eq(:poll)
      end

      it 'defaults to :webhook in production' do
        expect(Rails.env).to receive(:production?).and_return(true)
        expect(application.config.flipper.cloud.sync_method).to eq(:webhook)
      end
    end
  end
end
