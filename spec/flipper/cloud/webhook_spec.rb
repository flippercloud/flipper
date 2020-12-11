require 'helper'
require 'flipper/cloud/webhook'

RSpec.describe Flipper::Cloud::Webhook do
  let(:payload) { "some payload" }
  let(:secret) { "secret" }

  describe '.compute_signature' do
    it 'computes signature that can be verified' do
      timestamp = Time.now
      signature = Flipper::Cloud::Webhook.compute_signature(timestamp, payload, secret)
      header = generate_header(timestamp: timestamp, signature: signature)
      expect(Flipper::Cloud::Webhook.verify_header(payload, header, secret)).to be(true)
    end
  end

  describe ".generate_header" do
    it "generates a header in valid format" do
      timestamp = Time.now
      signature = Flipper::Cloud::Webhook.compute_signature(timestamp, payload, secret)
      version = "v1"
      header = Flipper::Cloud::Webhook.generate_header(
        timestamp,
        signature,
        version: version
      )
      expect(header).to eq("t=#{timestamp.to_i},#{version}=#{signature}")
    end
  end

  describe ".verify_signature_header" do
    it "raises a VerificationError when the header does not have the expected format" do
      header = "i'm not even a real signature header"
      expect {
        Flipper::Cloud::Webhook.verify_header(payload, header, "secret")
      }.to raise_error(Flipper::Cloud::Signature::VerificationError, "Unable to extract timestamp and signatures from header")
    end

    it "raises a VerificationError when there are no signatures with the expected version" do
      header = generate_header(version: "v0")
      expect {
        Flipper::Cloud::Webhook.verify_header(payload, header, "secret")
      }.to raise_error(Flipper::Cloud::Signature::VerificationError, /No signatures found with expected version/)
    end

    it "raises a VerificationError when there are no valid signatures for the payload" do
      header = generate_header(signature: "bad_signature")
      expect {
        Flipper::Cloud::Webhook.verify_header(payload, header, "secret")
      }.to raise_error(Flipper::Cloud::Signature::VerificationError, "No signatures found matching the expected signature for payload")
    end

    it "raises a VerificationError when the timestamp is not within the tolerance" do
      header = generate_header(timestamp: Time.now - 15)
      expect {
        Flipper::Cloud::Webhook.verify_header(payload, header, secret, tolerance: 10)
      }.to raise_error(Flipper::Cloud::Signature::VerificationError, /Timestamp outside the tolerance zone/)
    end

    it "returns true when the header contains a valid signature and the timestamp is within the tolerance" do
      header = generate_header
      expect(Flipper::Cloud::Webhook.verify_header(payload, header, secret, tolerance: 10)).to be(true)
    end

    it "returns true when the header contains at least one valid signature" do
      header = generate_header + ",v1=bad_signature"
      expect(Flipper::Cloud::Webhook.verify_header(payload, header, secret, tolerance: 10)).to be(true)
    end

    it "returns true when the header contains a valid signature and the timestamp is off but no tolerance is provided" do
      header = generate_header(timestamp: Time.at(12_345))
      expect(Flipper::Cloud::Webhook.verify_header(payload, header, secret)).to be(true)
    end
  end

  private

  def generate_header(options = {})
    options[:secret] ||= secret
    options[:version] ||= Flipper::Cloud::Signature::DEFAULT_VERSION
    signature = Flipper::Cloud::Signature.new(secret: options[:secret], version: options[:version])

    options[:timestamp] ||= Time.now
    options[:payload] ||= payload
    options[:signature] ||= signature.generate(options[:payload], options[:timestamp])

    signature.header(options[:signature], options[:timestamp])
  end
end
