require "zlib"
require "stringio"

module Flipper
  module Serializers
    module Gzip
      module_function

      class Stream < StringIO
        def initialize(*)
          super
          set_encoding "BINARY"
        end
        def close; rewind; end
      end

      def serialize(source)
        return if source.nil?
        output = Stream.new
        gz = Zlib::GzipWriter.new(output)
        gz.write(source)
        gz.close
        output.string
      end

      def deserialize(source)
        return if source.nil?
        Zlib::GzipReader.wrap(StringIO.new(source), &:read)
      end
    end
  end
end
