require 'rails'
require 'flipper/railtie'

RSpec.describe Flipper::Railtie do
  let(:application) do
    Class.new(Rails::Application).new(
      railties: [Flipper::Railtie],
    ).tap do |app|
      app.config.eager_load = false
      app.run_load_hooks!
    end
  end

  before do
    ActiveSupport::Dependencies.autoload_paths = ActiveSupport::Dependencies.autoload_paths.dup
    ActiveSupport::Dependencies.autoload_once_paths = ActiveSupport::Dependencies.autoload_once_paths.dup
  end

  let(:config) { application.config.flipper }

  subject { application.initialize! }

  describe 'initializers' do
    it 'sets defaults' do
      expect(config.env_key).to eq("flipper")
      expect(config.memoize).to be(true)
      expect(config.preload).to be(true)
    end

    it "configures instrumentor on default instance" do
      subject

      expect(Flipper.instance.instrumenter).to eq(ActiveSupport::Notifications)
    end

    it 'uses Memoizer middleware if config.memoize = true' do
      expect(subject.middleware).to include(Flipper::Middleware::Memoizer)
    end

    it 'does not use Memoizer middleware if config.memoize = false' do
      # load but don't initialize
      config.memoize = false

      expect(subject.middleware).not_to include(Flipper::Middleware::Memoizer)
    end

    it 'passes config to memoizer' do
      # load but don't initialize
      config.update(
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
