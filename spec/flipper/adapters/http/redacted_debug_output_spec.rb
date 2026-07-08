require "flipper/adapters/http/redacted_debug_output"

RSpec.describe Flipper::Adapters::Http::RedactedDebugOutput do
  # Net::HTTP writes request headers to debug output via String#dump, so the
  # separators show up as the escaped "\r\n" sequence.
  let(:dumped_request) do
    ("POST /features HTTP/1.1\r\n" \
     "Content-Type: application/json\r\n" \
     "Accept-Encoding: gzip\r\n" \
     "Flipper-Cloud-Token: super-secret-token\r\n" \
     "Authorization: Basic dXNlcjpwYXNz\r\n\r\n").dump
  end

  describe ".wrap" do
    it "returns nil for nil" do
      expect(described_class.wrap(nil)).to be_nil
    end

    it "wraps a plain output object" do
      output = +""
      expect(described_class.wrap(output)).to be_a(described_class)
    end

    it "does not double-wrap" do
      wrapped = described_class.wrap(+"")
      expect(described_class.wrap(wrapped)).to be(wrapped)
    end
  end

  describe ".redact" do
    subject { described_class.redact(dumped_request) }

    it "redacts the flipper-cloud-token value" do
      expect(subject).to include("Flipper-Cloud-Token: [REDACTED]")
      expect(subject).not_to include("super-secret-token")
    end

    it "redacts the authorization value" do
      expect(subject).to include("Authorization: [REDACTED]")
      expect(subject).not_to include("dXNlcjpwYXNz")
    end

    it "leaves non-sensitive headers untouched" do
      expect(subject).to include("Content-Type: application/json")
      expect(subject).to include("Accept-Encoding: gzip")
    end

    it "is case-insensitive about header names" do
      redacted = described_class.redact("flipper-cloud-token: secret\r\n".dump)
      expect(redacted).not_to include("secret")
      expect(redacted).to include("[REDACTED]")
    end

    it "handles raw CRLF separators too" do
      redacted = described_class.redact("Flipper-Cloud-Token: secret\r\nAccept: */*\r\n")
      expect(redacted).not_to include("secret")
      expect(redacted).to include("Accept: */*")
    end

    it "returns non-string messages unchanged" do
      expect(described_class.redact(nil)).to be_nil
      expect(described_class.redact(42)).to eq(42)
    end
  end

  describe "#<<" do
    it "writes redacted output to the wrapped object" do
      output = +""
      wrapped = described_class.new(output)
      wrapped << dumped_request
      expect(output).not_to include("super-secret-token")
      expect(output).not_to include("dXNlcjpwYXNz")
      expect(output).to include("[REDACTED]")
    end

    it "returns self so writes can be chained" do
      wrapped = described_class.new(+"")
      expect(wrapped << "anything").to be(wrapped)
    end
  end

  it "delegates unknown methods to the wrapped output" do
    output = double("output", flush: :flushed)
    wrapped = described_class.new(output)
    expect(wrapped.flush).to eq(:flushed)
  end
end
