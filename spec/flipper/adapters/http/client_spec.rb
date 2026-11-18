require "flipper/adapters/http/client"

RSpec.describe Flipper::Adapters::Http::Client do
  describe "#initialize" do
    it "requires url" do
      expect { described_class.new }.to raise_error(KeyError, "key not found: :url")
    end

    it "sets default headers" do
      client = described_class.new(url: "http://example.com")
      expect(client.headers).to eq({
        'content-type' => 'application/json',
        'accept' => 'application/json',
        'user-agent' => "Flipper HTTP Adapter v#{Flipper::VERSION}",
      })
    end

    it "adds custom headers" do
      client = described_class.new(url: "http://example.com", headers: {'custom-header' => 'value'})
      expect(client.headers).to include('custom-header' => 'value')
    end

    it "overrides default headers with custom headers" do
      client = described_class.new(url: "http://example.com", headers: {'content-type' => 'text/plain'})
      expect(client.headers['content-type']).to eq('text/plain')
    end
  end

  it "leaves a URI passed as the url untouched" do
    url = URI("http://example.com/flipper/api/").freeze
    client = described_class.new(url: url)
    expect(client.uri.path).to eq("/flipper/api")
    expect(url.path).to eq("/flipper/api/")
  end

  describe "#add_header" do
    it "can add string header" do
      client = described_class.new(url: "http://example.com")
      client.add_header("key", "value")
      expect(client.headers.fetch("key")).to eq("value")
    end

    it "standardizes key to lowercase" do
      client = described_class.new(url: "http://example.com")
      client.add_header("Content-Type", "value")
      expect(client.headers.fetch("content-type")).to eq("value")
    end

    it "standardizes key to dashes" do
      client = described_class.new(url: "http://example.com")
      client.add_header(:content_type, "value")
      expect(client.headers.fetch("content-type")).to eq("value")
    end

    it "can add symbol header" do
      client = described_class.new(url: "http://example.com")
      client.add_header(:key, "value")
      expect(client.headers.fetch("key")).to eq("value")
    end

    it "overrides existing header" do
      client = described_class.new(url: "http://example.com")
      client.add_header("key", "value 1")
      client.add_header("key", "value 2")
      expect(client.headers.fetch("key")).to eq("value 2")
    end
  end

  describe "#get" do
    [
      ["http://example.com/flipper/api", "/features", "http://example.com/flipper/api/features"],
      ["http://example.com/flipper/api/", "/features", "http://example.com/flipper/api/features"],
      ["http://example.com/", "/features", "http://example.com/features"],
      ["http://example.com/flipper/api?token=abc", "/features?keys=a", "http://example.com/flipper/api/features?token=abc&keys=a"],
    ].each do |url, path, expected|
      it "requests #{expected} for #{path} under #{url}" do
        stub = stub_request(:get, expected)
        described_class.new(url: url).get(path)
        expect(stub).to have_been_requested
      end
    end
  end
end
