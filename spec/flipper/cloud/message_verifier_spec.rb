require 'helper'
require 'flipper/cloud/message_verifier'

RSpec.describe Flipper::Cloud::MessageVerifier do
  let(:payload) { "some payload" }
  let(:secret) { "secret" }
  let(:timestamp) { Time.now }

  describe "#generate" do
    it "generates signature that can be verified" do
      message_verifier = Flipper::Cloud::MessageVerifier.new(secret: secret)
      signature = message_verifier.generate(payload, timestamp)
      header = generate_header(timestamp: timestamp, signature: signature)
      expect(message_verifier.verify(payload, header)).to be(true)
    end
  end

  describe "#header" do
    it "generates a header in valid format" do
      version = "v1"
      message_verifier = Flipper::Cloud::MessageVerifier.new(secret: secret, version: version)
      signature = message_verifier.generate(payload, timestamp)
      header = message_verifier.header(signature, timestamp)
      expect(header).to eq("t=#{timestamp.to_i},#{version}=#{signature}")
    end
  end

  describe ".header" do
    it "generates a header in valid format" do
      version = "v1"
      message_verifier = Flipper::Cloud::MessageVerifier.new(secret: secret, version: version)
      signature = message_verifier.generate(payload, timestamp)

      header = Flipper::Cloud::MessageVerifier.header(signature, timestamp, version)
      expect(header).to eq("t=#{timestamp.to_i},#{version}=#{signature}")
    end
  end

  describe "#verify" do
    it "raises a InvalidSignature when the header does not have the expected format" do
      header = "i'm not even a real signature header"
      expect {
        message_verifier = Flipper::Cloud::MessageVerifier.new(secret: "secret")
        message_verifier.verify(payload, header)
      }.to raise_error(Flipper::Cloud::MessageVerifier::InvalidSignature, "Unable to extract timestamp and signatures from header")
    end

    it "raises a InvalidSignature when there are no signatures with the expected version" do
      header = generate_header(version: "v0")
      expect {
        message_verifier = Flipper::Cloud::MessageVerifier.new(secret: "secret")
        message_verifier.verify(payload, header)
      }.to raise_error(Flipper::Cloud::MessageVerifier::InvalidSignature, /No signatures found with expected version/)
    end

    it "raises a InvalidSignature when there are no valid signatures for the payload" do
      header = generate_header(signature: "bad_signature")
      expect {
        message_verifier = Flipper::Cloud::MessageVerifier.new(secret: "secret")
        message_verifier.verify(payload, header)
      }.to raise_error(Flipper::Cloud::MessageVerifier::InvalidSignature, "No signatures found matching the expected signature for payload")
    end

    it "raises a InvalidSignature when the timestamp is not within the tolerance" do
      header = generate_header(timestamp: Time.now - 15)
      expect {
        message_verifier = Flipper::Cloud::MessageVerifier.new(secret: secret)
        message_verifier.verify(payload, header, tolerance: 10)
      }.to raise_error(Flipper::Cloud::MessageVerifier::InvalidSignature, /Timestamp outside the tolerance zone/)
    end

    it "returns true when the header contains a valid signature and the timestamp is within the tolerance" do
      header = generate_header
      message_verifier = Flipper::Cloud::MessageVerifier.new(secret: "secret")
      expect(message_verifier.verify(payload, header, tolerance: 10)).to be(true)
    end

    it "returns true when the header contains at least one valid signature" do
      header = generate_header + ",v1=bad_signature"
      message_verifier = Flipper::Cloud::MessageVerifier.new(secret: secret)
      expect(message_verifier.verify(payload, header, tolerance: 10)).to be(true)
    end

    it "returns true when the header contains a valid signature and the timestamp is off but no tolerance is provided" do
      header = generate_header(timestamp: Time.at(12_345))
      message_verifier = Flipper::Cloud::MessageVerifier.new(secret: secret)
      expect(message_verifier.verify(payload, header)).to be(true)
    end
  end

  private

  def generate_header(options = {})
    options[:secret] ||= secret
    options[:version] ||= "v1"

    message_verifier = Flipper::Cloud::MessageVerifier.new(secret: options[:secret], version: options[:version])

    options[:timestamp] ||= timestamp
    options[:payload] ||= payload
    options[:signature] ||= message_verifier.generate(options[:payload], options[:timestamp])

    Flipper::Cloud::MessageVerifier.header(options[:signature], options[:timestamp], options[:version])
  end
end
