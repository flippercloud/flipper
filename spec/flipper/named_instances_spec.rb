RSpec.describe "named Flipper instances" do
  def with_env(values)
    original = values.to_h { |key, _| [key, ENV[key]] }
    values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def configure_named(name = :cross_app, adapter: Flipper::Adapters::Memory.new)
    Flipper.configure do |config|
      config.named(name) do |named|
        named.adapter { adapter }
      end
    end
  end

  it "keeps the existing default configuration and instance API unchanged" do
    expect(Flipper.method(:configure).arity).to eq(0)
    expect(Flipper.method(:configuration).arity).to eq(0)
    expect(Flipper.method(:configuration=).arity).to eq(1)
    expect(Flipper.method(:instance).arity).to eq(0)
    expect(Flipper.method(:instance=).arity).to eq(1)

    default = Flipper.new(Flipper::Adapters::Memory.new)
    Flipper.configure { |config| config.default { default } }

    expect(Flipper.instance).to be(default)
  end

  it "configures a named child and exposes dynamic and direct access" do
    named_configuration = nil
    Flipper.configure do |config|
      named_configuration = config.named(:cross_app)
    end

    expect(named_configuration).to be_a(Flipper::NamedConfiguration)
    expect(named_configuration.name).to eq(:cross_app)
    expect(Flipper.named(:cross_app)).to be(Flipper.cross_app)
    expect(Flipper.cross_app.instance).to be_a(Flipper::DSL)
  end

  it "isolates feature state from the default instance" do
    configure_named

    Flipper.enable(:chat)

    expect(Flipper.enabled?(:chat)).to be(true)
    expect(Flipper.cross_app.enabled?(:chat)).to be(false)

    Flipper.cross_app.enable(:chat)

    expect(Flipper.cross_app.enabled?(:chat)).to be(true)
  end

  it "isolates group definitions from the default instance" do
    configure_named
    actor = Flipper::Actor.new("User;1")
    Flipper.register(:beta) { false }
    Flipper.cross_app.register(:beta) { true }

    Flipper.enable_group(:chat, :beta)
    Flipper.cross_app.enable_group(:chat, :beta)

    expect(Flipper.enabled?(:chat, actor)).to be(false)
    expect(Flipper.cross_app.enabled?(:chat, actor)).to be(true)
    expect(Flipper.group(:beta)).not_to be(Flipper.cross_app.group(:beta))
  end

  it "shares named group definitions with every thread-local DSL" do
    configure_named
    actor = Flipper::Actor.new("User;1")
    Flipper.cross_app.register(:beta) { true }
    Flipper.cross_app.enable_group(:chat, :beta)

    expect(Thread.new { Flipper.cross_app.enabled?(:chat, actor) }.value).to be(true)
  end

  it "keeps late default group registration visible to the existing default DSL" do
    actor = Flipper::Actor.new("User;1")
    default = Flipper.instance
    Flipper.register(:beta) { true }
    default.enable_group(:chat, :beta)

    expect(default.enabled?(:chat, actor)).to be(true)
  end

  it "resolves feature expressions within the named instance" do
    configure_named
    Flipper.enable(:dependency)
    Flipper.cross_app.enable_expression(:chat, Flipper.feature_enabled(:dependency))

    expect(Flipper.cross_app.enabled?(:chat)).to be(false)

    Flipper.cross_app.enable(:dependency)

    expect(Flipper.cross_app.enabled?(:chat)).to be(true)
  end

  it "keeps circular expression tracking isolated by named instance" do
    configure_named
    Flipper.enable(:dependency)
    Flipper.cross_app.enable_expression(:chat, Flipper.feature_enabled(:dependency))
    evaluating = Thread.current[Flipper::Expressions::FeatureEnabled::EVALUATING_KEY] = Set.new(["dependency"])

    expect(Flipper.cross_app.enabled?(:chat)).to be(false)

    Flipper.cross_app.enable(:dependency)

    expect(Flipper.cross_app.enabled?(:chat)).to be(true)
  ensure
    evaluating&.clear
  end

  it "uses a separate DSL in each thread with a shared configured adapter" do
    adapter = Flipper::Adapters::Memory.new
    configure_named(adapter: adapter)
    main_instance = Flipper.cross_app.instance
    other_instance = Thread.new { Flipper.cross_app.instance }.value

    expect(other_instance).not_to be(main_instance)
    expect(other_instance.adapter.adapter).to be(adapter)
    expect(main_instance.adapter.adapter).to be(adapter)
  end

  it "invalidates cached DSLs in other threads when named configuration changes" do
    configure_named
    named_configuration = Flipper.configuration.named_configuration(:cross_app)
    ready = Queue.new
    continue = Queue.new

    thread = Thread.new do
      original = Flipper.cross_app.instance
      ready << original
      continue.pop
      [original, Flipper.cross_app.instance]
    end

    ready.pop
    replacement = Flipper.new(Flipper::Adapters::Memory.new)
    named_configuration.default { replacement }
    continue << true
    original, current = thread.value

    expect(current).not_to be(original)
    expect(current).to be(replacement)
  end

  it "keeps retained proxies current when configuration is replaced" do
    configure_named
    retained = Flipper.cross_app
    original = retained.instance

    replacement_configuration = Flipper::Configuration.new
    replacement = Flipper.new(Flipper::Adapters::Memory.new)
    replacement_configuration.named(:cross_app).default { replacement }
    Flipper.configuration = replacement_configuration

    expect(Flipper.cross_app).to be(retained)
    expect(retained.instance).to be(replacement)
    expect(retained.instance).not_to be(original)
  end

  it "removes generated accessors when configuration is cleared" do
    configure_named
    expect(Flipper).to respond_to(:cross_app)

    Flipper.configuration = nil

    expect(Flipper).not_to respond_to(:cross_app)
    expect { Flipper.named(:cross_app) }.
      to raise_error(Flipper::NamedInstanceNotFound)
  end

  it "keeps accessors consistent when configuration raises after registration" do
    expect do
      Flipper.configure do |config|
        config.named(:cross_app)
        raise "configuration failed"
      end
    end.to raise_error("configuration failed")

    expect(Flipper.configuration.named_instance_names).to include(:cross_app)
    expect(Flipper.cross_app).to be(Flipper.named(:cross_app))
  end

  it "rolls back a named registration when its configuration block raises" do
    expect do
      Flipper.configure do |config|
        config.named(:cross_app) { raise "named configuration failed" }
      end
    end.to raise_error("named configuration failed")

    expect(Flipper.configuration.named_instance_names).not_to include(:cross_app)
    expect(Flipper).not_to respond_to(:cross_app)
  end

  it "rejects duplicate names" do
    expect do
      Flipper.configure do |config|
        config.named(:cross_app)
        config.named(:cross_app)
      end
    end.to raise_error(Flipper::DuplicateNamedInstance)
  end

  it "rejects nested named instances" do
    named = Flipper.configuration.named(:cross_app)

    expect { named.named(:nested) }.
      to raise_error(Flipper::InvalidConfigurationValue, /cannot be nested/)
  end

  it "rejects invalid and conflicting names" do
    expect { Flipper.configuration.named("cross-app") }.
      to raise_error(Flipper::InvalidNamedInstanceName, /lowercase snake case/)
    expect { Flipper.configuration.named(:configuration) }.
      to raise_error(Flipper::InvalidNamedInstanceName, /existing Flipper method/)
    expect { Flipper.configuration.named(:display) }.
      to raise_error(Flipper::InvalidNamedInstanceName, /existing Flipper method/)
  end

  it "does not break custom default configuration objects" do
    custom = Object.new
    default = Flipper.new(Flipper::Adapters::Memory.new)
    custom.define_singleton_method(:default) { default }

    Flipper.configuration = custom

    expect(Flipper.instance).to be(default)
    expect { Flipper.named(:cross_app) }.
      to raise_error(Flipper::NamedInstanceNotFound)
  end

  it "works without Cloud and does not require Cloud configuration" do
    configure_named

    expect(Flipper.cross_app.instance.class).to be(Flipper::DSL)
  end

  it "uses only name-scoped environment credentials for named Cloud" do
    with_env(
      "FLIPPER_CLOUD_TOKEN" => "default-token",
      "FLIPPER_CLOUD_SYNC_SECRET" => "default-secret",
      "FLIPPER_CLOUD_CROSS_APP_TOKEN" => "named-token",
      "FLIPPER_CLOUD_CROSS_APP_SYNC_SECRET" => "named-secret"
    ) do
      Flipper.configure do |config|
        config.named(:cross_app) { |named| named.cloud }
      end

      cloud = Flipper.cross_app.instance.cloud_configuration

      expect(cloud.token).to eq("named-token")
      expect(cloud.sync_secret).to eq("named-secret")
    end
  end

  it "never falls back to default Cloud credentials for a named instance" do
    with_env(
      "FLIPPER_CLOUD_TOKEN" => "default-token",
      "FLIPPER_CLOUD_SYNC_SECRET" => "default-secret",
      "FLIPPER_CLOUD_CROSS_APP_TOKEN" => nil,
      "FLIPPER_CLOUD_CROSS_APP_SYNC_SECRET" => nil
    ) do
      Flipper.configure do |config|
        config.named(:cross_app) { |named| named.cloud }
      end

      expect { Flipper.cross_app.instance }.
        to raise_error(Flipper::InvalidConfigurationValue, /CROSS_APP_TOKEN/)
    end
  end

  it "prefers explicit named Cloud credentials over scoped environment credentials" do
    with_env(
      "FLIPPER_CLOUD_CROSS_APP_TOKEN" => "environment-token",
      "FLIPPER_CLOUD_CROSS_APP_SYNC_SECRET" => "environment-secret"
    ) do
      Flipper.configure do |config|
        config.named(:cross_app) do |named|
          named.cloud(token: "explicit-token", sync_secret: "explicit-secret")
        end
      end

      cloud = Flipper.cross_app.instance.cloud_configuration

      expect(cloud.token).to eq("explicit-token")
      expect(cloud.sync_secret).to eq("explicit-secret")
    end
  end

  it "prefers named Rails-style credentials over scoped environment credentials" do
    with_env(
      "FLIPPER_CLOUD_CROSS_APP_TOKEN" => "environment-token",
      "FLIPPER_CLOUD_CROSS_APP_SYNC_SECRET" => "environment-secret"
    ) do
      named = Flipper.configuration.named(:cross_app)
      named.cloud

      resolved = named.resolve_cloud_credentials({
        token: "credentials-token",
        sync_secret: "credentials-secret",
      })

      expect(resolved[:token]).to eq("credentials-token")
      expect(resolved[:sync_secret]).to eq("credentials-secret")
    end
  end
end
