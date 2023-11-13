require "zlib"
require "stringio"

module Flipper
  module Serializers
    module Gzip
      module_function

      def serialize(source)
        output = StringIO.new
        gz = Zlib::GzipWriter.new(output)
        gz.write(source)
        gz.close
        output.string
      end

      def deserialize(source)
        Zlib::GzipReader.wrap(StringIO.new(source), &:read)
      end
    end
  end
end
