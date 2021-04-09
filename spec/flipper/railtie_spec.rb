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

  subject do
    application.initialize!
    application
  end

  describe 'config' do
    it 'memoizer.preload_all defaults to true' do
      expect(subject.config.flipper.memoizer.preload_all).to eq(true)
    end
  end

  describe 'initializers' do
    it 'adds Memoizer middleware by default' do
      expect(application.config.flipper.memoizer).to eq(preload_all: true)
      expect(Flipper::Middleware::Memoizer).to receive(:new).with(application.routes, preload_all: true)
      expect(subject.middleware.last).to eq(Flipper::Middleware::Memoizer)
    end

    it 'does not use app memoizer if config.flipper.memoizer = false' do
      application.config.flipper.memoizer = false
      expect(subject.middleware.last).not_to eq(Flipper::Middleware::Memoizer)
    end

    it 'passes preload config to memoizer' do
      expect(Flipper::Middleware::Memoizer).to receive(:new).with(application.routes, preload: [:stats, :search])
      application.config.flipper.memoizer.delete :preload_all
      application.config.flipper.memoizer.preload = [:stats, :search]
      subject
    end

    it "defines #flipper_id on AR::Base" do
      application.initialize!
      require 'active_record'
      expect(ActiveRecord::Base.ancestors).to include(Flipper::Identifier)
    end
  end
end
