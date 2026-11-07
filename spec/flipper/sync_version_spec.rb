require "flipper/adapters/http"
require "flipper/adapters/poll"
require "flipper/cloud/configuration"

# End to end: a response older than one already applied must never replace
# the newer flags, whichever sync path delivers it.
RSpec.describe "Sync version guard" do
  let(:url) { "https://www.flippercloud.io/adapter" }

  def body(enabled)
    JSON.generate(features: [
      { key: "search", gates: [{ key: "boolean", value: enabled }] },
    ])
  end

  def respond_with(*responses)
    stub_request(:get, %r{\A#{Regexp.escape(url)}/features\?}).to_return(
      *responses.map do |enabled, version|
        headers = version ? { "flipper-sync-version" => version.to_s } : {}
        { status: 200, body: body(enabled), headers: headers }
      end
    )
  end

  def http_adapter(token = "asdf")
    Flipper::Adapters::Http.new(url: url, headers: { "flipper-cloud-token" => token })
  end

  def new_poller
    Flipper::Poller.new(
      remote_adapter: http_adapter,
      start_automatically: false,
      shutdown_automatically: false,
    )
  end

  def enabled?(adapter)
    adapter.get(Flipper::Feature.new(:search, adapter))[:boolean] == "true"
  end

  describe "poll" do
    it "keeps newer flags when a later poll returns an older version" do
      respond_with [true, 10], [false, 8]
      poller = new_poller
      local = Flipper::Adapters::Memory.new
      poll = Flipper::Adapters::Poll.new(poller, local)
      allow(poller).to receive(:start)

      expect(enabled?(poll)).to be(true)

      poller.sync
      expect(enabled?(poller.adapter)).to be(true)
      expect(enabled?(poll)).to be(true)
      expect(enabled?(local)).to be(true)
    end

    it "applies an older version from a different environment" do
      respond_with [true, 10]
      local = Flipper::Adapters::Memory.new
      Flipper::Adapters::Sync::Synchronizer.new(local, http_adapter("prod")).call
      expect(enabled?(local)).to be(true)

      respond_with [false, 3]
      Flipper::Adapters::Sync::Synchronizer.new(local, http_adapter("staging")).call
      expect(enabled?(local)).to be(false)
    end

    it "behaves like before when responses have no version header" do
      respond_with [true, nil], [false, nil]
      poller = new_poller
      local = Flipper::Adapters::Memory.new
      poll = Flipper::Adapters::Poll.new(poller, local)
      allow(poller).to receive(:start)

      expect(enabled?(poll)).to be(true)
      poller.sync
      expect(enabled?(poll)).to be(false)
    end
  end

  describe "shared local adapter" do
    it "does not let a process with an older version overwrite newer flags" do
      shared = Flipper::Adapters::Memory.new

      # Process A sees version 10.
      respond_with [true, 10]
      poller_a = new_poller
      allow(poller_a).to receive(:start)
      poll_a = Flipper::Adapters::Poll.new(poller_a, shared)
      expect(enabled?(poll_a)).to be(true)

      # Process B is served a cached version 8 by another data center. Its
      # own poller has never seen anything newer.
      respond_with [false, 8]
      poller_b = new_poller
      allow(poller_b).to receive(:start)
      poller_b.sync
      poll_b = Flipper::Adapters::Poll.new(poller_b, shared)

      expect(enabled?(poller_b.adapter)).to be(false)
      expect(enabled?(poll_b)).to be(true)
      expect(enabled?(shared)).to be(true)
    end
  end

  describe "webhook" do
    it "keeps newer flags when a later sync returns an older version" do
      configuration = Flipper::Cloud::Configuration.new(token: "asdf", url: url, telemetry_enabled: false)

      respond_with [true, 10]
      configuration.sync(cache_bust: true)
      expect(enabled?(configuration.local_adapter)).to be(true)

      respond_with [false, 8]
      configuration.sync(cache_bust: true)
      expect(enabled?(configuration.local_adapter)).to be(true)

      respond_with [false, 11]
      configuration.sync(cache_bust: true)
      expect(enabled?(configuration.local_adapter)).to be(false)
    end
  end
end
