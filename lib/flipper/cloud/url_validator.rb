require "uri"

module Flipper
  module Cloud
    module UrlValidator
      def self.validate(value)
        url = value.to_s.dup
        uri = URI(url)

        return url.freeze if uri.is_a?(URI::HTTPS) && !uri.host.to_s.empty?

        raise_invalid_url(value)
      rescue URI::InvalidURIError
        raise_invalid_url(value)
      end

      def self.raise_invalid_url(value)
        raise ArgumentError,
          "Flipper::Cloud url must use https but was #{value.inspect}. " \
          "https is required so your token is never sent in cleartext."
      end
      private_class_method :raise_invalid_url
    end
    private_constant :UrlValidator
  end
end
