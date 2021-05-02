require 'helper'
require 'rails'
require 'flipper/railtie'

RSpec.describe Flipper::Railtie do
  let(:application) do
    app = Class.new(Rails::Application).new(
      railties: [Flipper::Railtie],
      ordered_railties: [Flipper::Railtie]
    )
    app.config.eager_load = false
    app.config.logger = ActiveSupport::Logger.new($stdout)
    app.run_load_hooks!
  end

  before do
    Rails.application = nil
  end

  subject do
    application.initialize!
    application
  end

  describe 'initializers' do
    it 'uses Memoizer middleware if config.memoize = true' do
      expect(subject.middleware.last).to eq(Flipper::Middleware::Memoizer)
    end

    it 'does not use Memoizer middleware if config.memoize = false' do
      application # load but don't initialize
      Flipper.configuration.memoize = false

      expect(subject.middleware.last).not_to eq(Flipper::Middleware::Memoizer)
    end

    it 'passes config to memoizer' do
      application # load but don't initialize

      Flipper.configure do |config|
        config.env_key = 'my_flipper'
        config.preload = [:stats, :search]
      end

      expect(Flipper::Middleware::Memoizer).to receive(:new).with(application.routes,
          env_key: 'my_flipper', preload: [:stats, :search], if: nil
      )

      subject # initialize
    end

    it "defines #flipper_id on AR::Base" do
      subject
      require 'active_record'
      expect(ActiveRecord::Base.ancestors).to include(Flipper::Identifier)
    end
  end
end
