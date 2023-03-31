# Flipper Expressions

> A schema for Flipper Expressions

The structure for flipper Expressions is defined in [`schemas/schema.json`](./schemas/schema.json) using [JSON Schema](https://json-schema.org) ([draft-07](https://json-schema.org/specification-links.html#draft-7)).

To learn more about JSON Schema, read [Understanding JSON Schema](https://json-schema.org/understanding-json-schema/) or the [Ajv JSON schema validator docs](https://ajv.js.org/json-schema.html).

## Adding a new expression

1. Describe arguments by creating a new file in [`schemas/`](schemas/) named `NewName.schema.json`. You can copy an existing function that has similar semantics to get started.
2. Add the new function in [`schemas/schema.json`](schemas/schema.json) to `$defs/function`.
3. Create a new file in [`examples/`](./examples) named `NewName.json` with valid and invalid examples for the new function. See other examples for inspiration.
4. Run `yarn test` in `packages/expressions` and ensure tests pass.
5. Implement the function in [`lib/flipper/expressions/`](../../lib/flipper/expressions/).
6. Run `rspec` to ensure tests pass.

See [this commit that adds Min/Max functions](https://github.com/jnunemaker/flipper/commit/ee46fab0cda21a32c3a921a8ed1fb94b0842b6b4) for a concrete example.
