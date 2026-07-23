require "flipper/cloud/migrate"
require "flipper/typecast"
require "webmock/rspec"

RSpec.describe Flipper::Cloud, ".migrate" do
  let(:flipper) { Flipper.new(Flipper::Adapters::Memory.new) }

  before do
    flipper.enable :search
    flipper.disable :analytics
    flipper.enable_percentage_of_actors :checkout, 50
  end

  around do |example|
    original = ENV["FLIPPER_CLOUD_URL"]
    ENV["FLIPPER_CLOUD_URL"] = "https://localhost:5555"
    example.run
  ensure
    ENV["FLIPPER_CLOUD_URL"] = original
  end

  def decompress_request_body
    raw = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last.body
    JSON.parse(Flipper::Typecast.from_gzip(raw))
  end

  describe ".migrate" do
    it "returns a MigrateResult with code and url on success" do
      stub_request(:post, "https://localhost:5555/api/migrate")
        .to_return(status: 200, body: '{"url":"https://localhost:5555/cloud/setup/abc123"}', headers: {"Content-Type" => "application/json"})

      result = Flipper::Cloud.migrate(flipper)

      expect(result).to be_a(Flipper::Cloud::MigrateResult)
      expect(result.code).to eq(200)
      expect(result.url).to eq("https://localhost:5555/cloud/setup/abc123")
    end

    it "sends export data and metadata in the request body" do
      stub = stub_request(:post, "https://localhost:5555/api/migrate")
        .to_return(status: 200, body: '{"url":"https://localhost:5555/cloud/setup/abc123"}')

      Flipper::Cloud.migrate(flipper, app_name: "MyApp")

      expect(stub).to have_been_requested
      body = decompress_request_body
      expect(body["metadata"]["app_name"]).to eq("MyApp")
      expect(body["export"]["version"]).to eq(1)
      expect(body["export"]["features"]).to have_key("search")
    end

    it "sends gzip-compressed request body" do
      stub = stub_request(:post, "https://localhost:5555/api/migrate")
        .with(headers: {"content-encoding" => "gzip"})
        .to_return(status: 200, body: '{"url":"https://localhost:5555/cloud/setup/abc"}')

      Flipper::Cloud.migrate(flipper)

      expect(stub).to have_been_requested
      body = decompress_request_body
      expect(body["export"]["features"]).to have_key("search")
    end

    it "handles error responses" do
      stub_request(:post, "https://localhost:5555/api/migrate")
        .to_return(status: 500, body: '{"error":"Internal Server Error"}')

      result = Flipper::Cloud.migrate(flipper)

      expect(result.code).to eq(500)
      expect(result.url).to be_nil
    end

    it "includes error message from response body" do
      stub_request(:post, "https://localhost:5555/api/migrate")
        .to_return(status: 422, body: '{"error":"Invalid export format"}')

      result = Flipper::Cloud.migrate(flipper)

      expect(result.code).to eq(422)
      expect(result.message).to eq("Invalid export format")
    end

    it "uses FLIPPER_CLOUD_URL environment variable" do
      stub = stub_request(:post, "https://localhost:5555/api/migrate")
        .to_return(status: 200, body: '{"url":"https://localhost:5555/cloud/setup/abc"}')

      Flipper::Cloud.migrate(flipper)

      expect(stub).to have_been_requested
    end

    it "sends content-type and accept headers" do
      stub = stub_request(:post, "https://localhost:5555/api/migrate")
        .with(headers: {
          "content-type" => "application/json",
          "accept" => "application/json",
        })
        .to_return(status: 200, body: '{"url":"https://localhost:5555/cloud/setup/abc"}')

      Flipper::Cloud.migrate(flipper)

      expect(stub).to have_been_requested
    end
  end

  describe ".push" do
    it "returns a MigrateResult with code on success" do
      stub_request(:post, "https://localhost:5555/adapter/import")
        .to_return(status: 204, body: "")

      result = Flipper::Cloud.push("test-token", flipper)

      expect(result).to be_a(Flipper::Cloud::MigrateResult)
      expect(result.code).to eq(204)
    end

    it "sends the token as a header" do
      stub = stub_request(:post, "https://localhost:5555/adapter/import")
        .with(headers: {"flipper-cloud-token" => "test-token"})
        .to_return(status: 204, body: "")

      Flipper::Cloud.push("test-token", flipper)

      expect(stub).to have_been_requested
    end

    it "requires HTTPS when sending the token" do
      ENV["FLIPPER_CLOUD_URL"] = "http://localhost:5555"

      expect { Flipper::Cloud.push("test-token", flipper) }.to raise_error(ArgumentError, /must use https/)
    end

    it "sends gzip-compressed export contents as the body" do
      stub = stub_request(:post, "https://localhost:5555/adapter/import")
        .with(headers: {"content-encoding" => "gzip"})
        .to_return(status: 204, body: "")

      Flipper::Cloud.push("test-token", flipper)

      expect(stub).to have_been_requested
      body = decompress_request_body
      expect(body["version"]).to eq(1)
      expect(body["features"]).to have_key("search")
    end

    it "handles error responses" do
      stub_request(:post, "https://localhost:5555/adapter/import")
        .to_return(status: 401, body: '{"error":"Unauthorized"}')

      result = Flipper::Cloud.push("bad-token", flipper)

      expect(result.code).to eq(401)
    end

    it "includes error message from response body" do
      stub_request(:post, "https://localhost:5555/adapter/import")
        .to_return(status: 401, body: '{"error":"Invalid token"}')

      result = Flipper::Cloud.push("bad-token", flipper)

      expect(result.code).to eq(401)
      expect(result.message).to eq("Invalid token")
    end
  end
end
