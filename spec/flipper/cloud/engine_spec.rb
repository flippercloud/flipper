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
      it 'uses presence of FLIPPER_CLOUD_SYNC_SECRET env variable to enable webhook' do
        with_modified_env 'FLIPPER_CLOUD_SYNC_SECRET' => 'xyz' do
          expect(application.config.flipper.cloud.sync_method).to eq(:webhook)
        end
      end

      it 'respects FLIPPER_CLOUD_SYNC_METHOD env variable' do
        with_modified_env 'FLIPPER_CLOUD_SYNC_METHOD' => 'webhook' do
          expect(application.config.flipper.cloud.sync_method).to eq(:webhook)
        end
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
