require 'helper'
require 'rails'
require 'flipper/railtie'

RSpec.describe Flipper::Railtie do
  let(:application) do
    Class.new(Rails::Application) do
      config.eager_load = false
      config.logger = ActiveSupport::Logger.new($stdout)
    end
  end

  before do
    Rails.application = nil
  end

  describe 'initializers' do
    it 'adds Memoizer middleware by default' do
      application.initialize!
      expect(application.middleware.last).to eq(Flipper::Middleware::Memoizer)
    end

    it 'does not use app memoizer if config.flipper.memoizer = false' do
      application.config.flipper.memoizer = false
      application.initialize!
      expect(application.middleware.last).not_to eq(Flipper::Middleware::Memoizer)
    end

    it 'passes preload config to memoizer' do
      expect(Flipper::Middleware::Memoizer).to receive(:new).with(application.routes, preload: [:stats, :search])
      application.config.flipper.memoizer.preload = [:stats, :search]
      application.initialize!
    end

    it 'passes preload_all config to memoizer' do
      expect(Flipper::Middleware::Memoizer).to receive(:new).with(application.routes, preload_all: true)
      application.config.flipper.memoizer.preload_all = true
      application.initialize!
    end

    it "defines #flipper_id on AR::Base" do
      application.initialize!
      require 'active_record'
      expect(ActiveRecord::Base.ancestors).to include(Flipper::Identifier)
    end
  end
end
