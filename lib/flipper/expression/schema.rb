require "json_schemer"

module Flipper
  class Expression
    class Schema < JSONSchemer::Schema::Draft7
      PATH =
        Pathname.new(File.expand_path("../../../packages/expressions", __dir__))

      def self.schemas
        @schemas ||=
          Hash[
            PATH
              .glob("schemas/*.json")
              .map { |path| [File.basename(path), JSON.parse(File.read(path))] }
          ]
      end

      def self.examples
        PATH
          .glob("examples/*.json")
          .map { |path| [File.basename(path), JSON.parse(File.read(path))] }
      end

      def initialize(schema = self.class.schemas["schema.json"])
        super(
          schema,
          insert_property_defaults: true,
          ref_resolver:
            lambda { |url| self.class.schemas[File.basename(url.path)] }
        )
      end
    end
  end
end
