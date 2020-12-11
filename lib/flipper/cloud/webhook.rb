require "openssl"
require "digest/sha2"

module Flipper
  module Cloud
    class Signature
      class VerificationError < StandardError; end

      DEFAULT_VERSION = "v1"

      def initialize(secret: secret, version: nil)
        @secret = secret
        @version = version || DEFAULT_VERSION

        raise ArgumentError, "secret should be a string" unless @secret.is_a?(String)
        raise ArgumentError, "version should be a string" unless @version.is_a?(String)
      end

      def generate(payload, timestamp)
        raise ArgumentError, "timestamp should be an instance of Time" unless timestamp.is_a?(Time)
        raise ArgumentError, "payload should be a string" unless payload.is_a?(String)

        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @secret, "#{timestamp.to_i}.#{payload}")
      end

      def header(signature, timestamp)
        raise ArgumentError, "timestamp should be an instance of Time" unless timestamp.is_a?(Time)
        raise ArgumentError, "signature should be a string" unless signature.is_a?(String)

        "t=#{timestamp.to_i},#{@version}=#{signature}"
      end

      # Public: Verifies the signature header for a given payload.
      #
      # Raises a VerificationError in the following cases:
      # - the header does not match the expected format
      # - no signatures found with the expected scheme
      # - no signatures matching the expected signature
      # - a tolerance is provided and the timestamp is not within the
      #   tolerance
      #
      # Returns true otherwise.
      def verify(payload, header, tolerance: nil)
        begin
          timestamp, signatures = get_timestamp_and_signatures(header)
        rescue StandardError
          raise VerificationError, "Unable to extract timestamp and signatures from header"
        end

        if signatures.empty?
          raise VerificationError, "No signatures found with expected version #{@version}"
        end

        expected_sig = generate(payload, timestamp)
        unless signatures.any? { |s| secure_compare(expected_sig, s) }
          raise VerificationError, "No signatures found matching the expected signature for payload"
        end

        if tolerance && timestamp < Time.now - tolerance
          raise VerificationError, "Timestamp outside the tolerance zone (#{Time.at(timestamp)})"
        end

        true
      end

      private

      # Extracts the timestamp and the signature(s) with the desired scheme
      # from the header
      def get_timestamp_and_signatures(header)
        list_items = header.split(/,\s*/).map { |i| i.split("=", 2) }
        timestamp = Integer(list_items.select { |i| i[0] == "t" }[0][1])
        signatures = list_items.select { |i| i[0] == @version }.map { |i| i[1] }
        [Time.at(timestamp), signatures]
      end

      # Private
      def fixed_length_secure_compare(a, b)
        raise ArgumentError, "string length mismatch." unless a.bytesize == b.bytesize
        l = a.unpack "C#{a.bytesize}"
        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res == 0
      end

      # Private
      def secure_compare(a, b)
        fixed_length_secure_compare(::Digest::SHA256.digest(a), ::Digest::SHA256.digest(b)) && a == b
      end
    end

    class Webhook

      DEFAULT_VERSION = "v1"

      # Public: Computes a webhook signature given a time, a payload, and a
      # signing secret.
      def self.compute_signature(timestamp, payload, secret)
        Signature.new(secret: secret).generate(payload, timestamp)
      end

      # Public: Generates a value that would be added to a `Flipper-Cloud-Signature`
      # for a given webhook payload.
      def self.generate_header(timestamp, signature, version: DEFAULT_VERSION)
        Signature.new(secret: "", version: version).header(signature, timestamp)
      end

      def self.verify_header(payload, header, secret, tolerance: nil, version: DEFAULT_VERSION)
        Signature.new(secret: secret, version: version).verify(payload, header, tolerance: tolerance)
      end
    end
  end
end
