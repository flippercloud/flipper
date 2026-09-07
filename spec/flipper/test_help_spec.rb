RSpec.describe Flipper::TestHelp do
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

    described_class.flipper_reset

    expect(Flipper.cross_app.enabled?(:chat)).to be(false)
    expect(Flipper.cross_app.group_exists?(:beta)).to be(true)
  end
end
