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
    it 'sets defaults' do
      expect(application.config.flipper.env_key).to eq("flipper")
      expect(application.config.flipper.memoize).to be(true)
      expect(application.config.flipper.preload).to be(true)
    end

    it "configures instrumentor on default instance" do
      subject

      expect(Flipper.instance.instrumenter).to eq(ActiveSupport::Notifications)
    end

    it 'uses Memoizer middleware if config.memoize = true' do
      expect(subject.middleware.last).to eq(Flipper::Middleware::Memoizer)
    end

    it 'does not use Memoizer middleware if config.memoize = false' do
      # load but don't initialize
      application.config.flipper.memoize = false

      expect(subject.middleware.last).not_to eq(Flipper::Middleware::Memoizer)
    end

    it 'passes config to memoizer' do
      # load but don't initialize
      application.config.flipper.update(
        env_key: 'my_flipper',
        preload: [:stats, :search]
      )

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
