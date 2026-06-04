module Flipper
  class Expression
    # Validates expression values against the JSON Schema vendored from
    # https://github.com/flippercloud/expressions (see lib/flipper/expression/schemas).
    #
    # Validation is optional and requires the `json_schemer` gem. Core flipper does
    # not depend on it so that apps that only evaluate flags pay no extra weight.
    class Schema
      # Internal: Directory holding the vendored JSON Schema files.
      ROOT = File.expand_path("schemas", __dir__)

      # Internal: Filename => parsed schema, loaded once.
      def self.schemas
        @schemas ||= Dir[File.join(ROOT, "*.json")].each_with_object({}) do |path, hash|
          hash[File.basename(path)] = Flipper::Typecast.from_json(File.read(path))
        end
      end

      # Internal: Shared instance for the root schema. Building a JSONSchemer is
      # relatively expensive, so reuse one across validations.
      def self.instance
        @instance ||= new
      end

      def initialize(schema = self.class.schemas["schema.json"])
        require "json_schemer"
        @schemer = JSONSchemer.schema(schema, ref_resolver: method(:resolve))
      rescue LoadError
        raise LoadError, "Validating Flipper expressions requires the `json_schemer` gem. " \
                         "Add `gem \"json_schemer\"` to your Gemfile to enable it."
      end

      # Public: Returns an Enumerable of JSON Schema validation errors (empty when valid).
      def validate(value)
        @schemer.validate(value)
      end

      # Public: Returns true if the value is a structurally valid expression.
      def valid?(value)
        @schemer.valid?(value)
      end

      private

      # Internal: Resolve a $ref to a sibling schema file by basename.
      def resolve(uri)
        self.class.schemas[File.basename(uri.path)]
      end
    end
  end
end
