require "zlib"
require "stringio"

module Flipper
  module Serializers
    class Gzip
      def self.serialize(source)
        return if source.nil?
        output = StringIO.new
        gz = Zlib::GzipWriter.new(output)
        gz.write(source)
        gz.close
        output.string
      end

      def self.deserialize(source)
        return if source.nil?
        Zlib::GzipReader.wrap(StringIO.new(source), &:read)
      end
    end
  end
end
