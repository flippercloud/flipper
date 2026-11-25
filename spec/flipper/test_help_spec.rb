RSpec.describe Flipper::TestHelp do
  it "does not remove features from an instance memoized before configure" do
    app_adapter = Flipper::Adapters::Memory.new
    Flipper.configure do |config|
      config.adapter { app_adapter }
    end
    Flipper.enable(:checkout)

    described_class.flipper_configure
    described_class.flipper_reset

    expect(app_adapter.features).to eq(Set["checkout"])
  end

  it "uses a separate shared Memory adapter for each named instance" do
    Flipper.configure do |config|
      config.named(:cross_app)
      config.named(:internal)
    end

    described_class.flipper_configure
    Flipper.cross_app.enable(:chat)

    expect(Thread.new { Flipper.cross_app.enabled?(:chat) }.value).to be(true)
    expect(Flipper.internal.enabled?(:chat)).to be(false)
    expect(Flipper.enabled?(:chat)).to be(false)
  end

  it "replaces a named Cloud default without contacting Cloud" do
    Flipper.configure do |config|
      config.named(:cross_app) do |named|
        named.cloud(token: "cloud-token", sync_secret: "cloud-secret")
      end
    end

    described_class.flipper_configure

    expect(Flipper.cross_app.instance.class).to be(Flipper::DSL)
    expect(a_request(:any, /flippercloud/)).not_to have_been_made
  end

  it "replaces a named polling Cloud instance added after test setup" do
    described_class.flipper_configure
    Flipper.configure do |config|
      config.named(:cross_app) do |named|
        named.cloud(token: "cloud-token", sync_secret: "")
      end
    end

    described_class.flipper_reset

    expect(Flipper.cross_app.instance.class).to be(Flipper::DSL)
    expect(a_request(:any, /flippercloud/)).not_to have_been_made
  end

  it "shares Memory for a non-Cloud named instance added after test setup" do
    described_class.flipper_configure
    Flipper.configure { |config| config.named(:cross_app) }

    described_class.flipper_reset
    Flipper.cross_app.enable(:chat)

    expect(Thread.new { Flipper.cross_app.enabled?(:chat) }.value).to be(true)
  end

  it "clears named features while preserving registered groups" do
    Flipper.configure do |config|
      config.named(:cross_app)
    end
    Flipper.cross_app.register(:beta) { true }
    described_class.flipper_configure
    Flipper.cross_app.enable(:chat)
    retained = Flipper.cross_app.instance

    described_class.flipper_reset

    expect(retained.enabled?(:chat)).to be(false)
    expect(Flipper.cross_app.enabled?(:chat)).to be(false)
    expect(Flipper.cross_app.group_exists?(:beta)).to be(true)
  end

  it "reuses named test adapters across examples while clearing features" do
    Flipper.configure { |config| config.named(:cross_app) }
    described_class.flipper_configure
    named = Flipper.configuration.named_configuration(:cross_app)
    version = named.version
    # RSpec and Minitest call flipper_reset on each example, not on the module.
    example_class = Class.new { include Flipper::TestHelp }

    example_class.new.flipper_reset
    Flipper.enable(:search)
    Flipper.cross_app.enable(:chat)
    retained = Flipper.cross_app.instance

    example_class.new.flipper_reset

    expect(named.version).to eq(version)
    expect(Flipper.enabled?(:search)).to be(false)
    expect(retained.enabled?(:chat)).to be(false)
    expect(Flipper.cross_app.enabled?(:chat)).to be(false)
    retained.enable(:shared)
    expect(Flipper.cross_app.enabled?(:shared)).to be(true)
  end

  it "clears named features enabled in another thread while this one memoizes" do
    Flipper.configure { |config| config.named(:cross_app) }
    described_class.flipper_configure
    example_class = Class.new { include Flipper::TestHelp }

    example_class.new.flipper_reset
    Flipper.cross_app.adapter.memoize = true
    Flipper.cross_app.features
    Thread.new { Flipper.cross_app.enable(:chat) }.join

    example_class.new.flipper_reset

    expect(Flipper.cross_app.enabled?(:chat)).to be(false)
  end

  it "clears the previous test adapter when a named configuration changes" do
    Flipper.configure { |config| config.named(:cross_app) }
    described_class.flipper_configure
    Flipper.cross_app.enable(:chat)
    retained = Flipper.cross_app.instance
    named = Flipper.configuration.named_configuration(:cross_app)
    named.cloud(token: "cloud-token", sync_secret: "")

    described_class.flipper_reset

    expect(retained.enabled?(:chat)).to be(false)
    expect(Flipper.cross_app.instance).to be_a(Flipper::DSL)
    expect(Flipper.cross_app.enabled?(:chat)).to be(false)
    expect(a_request(:any, /flippercloud/)).not_to have_been_made
  end
end
