# Named Flipper Instances

Status: Implemented locally; pending review

## Motivation

An organization may run many Rails applications, with one Flipper Cloud project per
product for feature isolation and permissions, while also needing a separate Cloud
project for features shared across every product.

Today each application can configure only the process-wide `Flipper` instance. A
shared feature therefore has to be copied into every product project and kept in
sync manually.

The desired application code is:

```ruby
Flipper.enabled?(:product_feature, person)
Flipper.cross_app.enabled?(:shared_feature, person)

# Optional application-level alias.
CrossAppFlipper = Flipper.cross_app
CrossAppFlipper.enabled?(:shared_feature, person)
```

Each named instance must have its own adapter stack, Cloud project, webhook,
memoization, preload configuration, groups, and permissions.

Active Record table isolation is already supported by the adapter's `table_prefix:`
option and is not part of this work.

Named instances are a Flipper core feature, not a Flipper Cloud feature. A named
instance may use Memory, Active Record, Redis, or any other adapter without loading
Cloud. Cloud configuration is an optional capability of a named instance.

## Compatibility Requirement

This feature is additive. An application that does not configure a named instance
must behave exactly as it does today.

In particular:

- Keep the signatures and behavior of `Flipper.configure`, `Flipper.configuration`,
  `Flipper.configuration=`, `Flipper.instance`, and `Flipper.instance=` unchanged.
- Keep every existing top-level DSL delegate, global group API, environment variable,
  Rails initializer, middleware key, Cloud route, and test helper behavior unchanged.
- Keep the default instance in `Thread.current[:flipper_instance]`.
- Do not add middleware, routes, polling, telemetry, or adapter construction when no
  named instances are configured.
- Do not change default instrumentation payloads.
- Run the existing test suite without modifying existing assertions merely to
  accommodate the new feature. Add separate coverage for named behavior.

Avoid implementing the existing default as a public named instance. A parallel
named-instance path is less likely to change default lifecycle or lookup behavior.

## Public API

The implementation uses a named child configuration rather than a block that only
returns a DSL:

```ruby
Flipper.configure do |config|
  config.named(:cross_app) do |cross_app|
    cross_app.adapter do
      Flipper::Adapters::ActiveRecord.new(table_prefix: "cross_app_")
    end

    cross_app.cloud(path: "_flipper/cross_app")
  end
end

Flipper.cross_app.register(:beta_organizations) do |actor|
  actor.respond_to?(:beta_organization?) && actor.beta_organization?
end
```

Access would be available through both:

```ruby
Flipper.named(:cross_app)
Flipper.cross_app
```

`Flipper.named(:cross_app)` is the universal lookup API. `Flipper.cross_app` is
explicitly defined convenience sugar; it must not be implemented with a general
`method_missing`.

The returned object should be a stable proxy that resolves the current named,
thread-local DSL for every operation. That allows an application constant such as
`CrossAppFlipper = Flipper.cross_app` to continue working after configuration or test
state is reset instead of retaining a stale adapter.

### Names

A name must:

- normalize consistently to a symbol;
- be a valid Ruby method name for direct accessor generation;
- be unique among named instances; and
- not collide with any existing public, protected, or private method callable on
  `Flipper`, including inherited methods.

Invalid, duplicate, and reserved names should fail during configuration with a
specific exception. Replacing or clearing configuration must not leave stale
dynamically defined accessors behind.

## Why a Child Configuration

A simple factory such as `config.named(:cross_app) { Flipper::Cloud.new(...) }` is
enough to construct a DSL, but it leaves several behaviors outside the model:

- adapter composition with `config.use`;
- Rails strict and actor-limit wrappers;
- instrumentation;
- per-instance test adapters and reset behavior;
- group registration;
- memoization, preload, environment key, and Cloud route metadata; and
- explicit Cloud credentials without accidental fallback to the default project.

A child configuration can reuse the existing adapter builder and default factory
concept while adding only the metadata needed for named instances. Existing
`Flipper::Configuration` behavior must remain unchanged.

## Core Design

### Registry and lifecycle

- Store named configurations in the root `Flipper::Configuration`.
- Create one DSL per name per thread, analogous to the existing default instance.
- Version named configurations so replacement is observed by DSL caches in every
  thread; clearing only the thread that performed the replacement is insufficient.
- Use a collision-resistant internal thread-local container rather than creating one
  arbitrary thread-local key per user-supplied name.
- Keep group registries on the named configuration, not the thread-local DSL. Groups
  registered during boot must be visible to every request thread.
- Reset named thread-local DSLs whenever their configuration changes.
- Provide an internal reset path that tests can exercise without changing the
  existing `Flipper.instance=` contract.
- Make duplicate registration deterministic and thread safe.
- Define when Rails freezes the set of names used for automatic middleware and
  routes. A name registered after `config/initializers` cannot silently receive an
  incomplete request lifecycle.

### Groups

Groups cannot remain process-global for named instances. The same group name may
legitimately have different predicates in a product project and the cross-product
project.

Add group lookup and registration to the owning configuration/DSL. Update group gate
evaluation, feature group operations, group value wrapping, Cloud webhook reporting,
and UI/API validation to resolve groups through the owning instance.

The default DSL must continue to resolve the existing live global
`Flipper.groups_registry`. Do not copy that registry into the default configuration;
late calls to `Flipper.register` and `Flipper.groups_registry=` must retain their
current behavior.

Cloud sync stores enabled group names, not Ruby predicates. Every application using
the shared project must deploy the same named group definitions. The feature should
document this operational requirement; it cannot synchronize application code.
The applications must also produce the same `flipper_id` for shared actors. Cloud can
synchronize an enabled actor ID, but it cannot make different application actor
models agree on identity.

### Expressions

`feature_enabled` expressions currently call the top-level default `Flipper`. A
feature reference inside an expression must instead resolve through the DSL that owns
the expression.

- Named expressions only reference features in the same named instance.
- Default expressions keep their existing behavior.
- Circular-evaluation tracking must include instance identity as well as feature name
  so equal feature names in different instances do not interfere.
- Any new resolver passed into `Feature`, gates, types, or expressions must be
  optional and preserve current constructor behavior.

### Rails memoization and preload

Each configured named instance needs its own Rack environment key and memoizer pass:

1. Put the named proxy/DSL into its environment key with `SetupEnv`.
2. Run `Memoizer` with that same key and the named preload setting.
3. Ensure memoization is disabled in an `ensure` block, as it is for the default.

The default middleware and `flipper` environment key remain untouched. Environment
keys must be unique, and middleware order must allow default and named instances to
memoize and preload independently during the same request.

Rails settings such as instrumenter, strict mode, actor limit, memoize, and preload
need explicit inheritance rules. The likely default is to inherit the root Rails
setting and permit a named override, but this must be decided before implementation.

### Flipper Cloud

Each named Cloud instance must use an explicit token and sync secret for its project.
It must not accidentally inherit `FLIPPER_CLOUD_TOKEN` or
`FLIPPER_CLOUD_SYNC_SECRET`, which remain reserved for the default instance.

Named Cloud instances must be explicitly declared; do not discover instance names by
scanning environment variables. Once declared, a name may opt into Cloud and use
name-scoped automatic configuration. For `cross_app`, the proposed variables are:

```text
FLIPPER_CLOUD_CROSS_APP_TOKEN
FLIPPER_CLOUD_CROSS_APP_SYNC_SECRET
```

The corresponding Rails credentials are:

```yaml
flipper:
  cross_app:
    cloud_token: "..."
    cloud_sync_secret: "..."
```

Resolution order for named credentials is:

1. explicit named configuration;
2. named Rails credentials;
3. name-scoped environment variables; and
4. missing, which disables or rejects Cloud configuration as appropriate.

There is deliberately no fallback from a named credential to the default
`FLIPPER_CLOUD_TOKEN`, `FLIPPER_CLOUD_SYNC_SECRET`, or default Rails credential. The
existing default credential lookup and `Flipper::Cloud.new` behavior remain
unchanged. The implementation may need an additive Cloud configuration option that
disables default environment fallback when building a named Cloud DSL.

Each project also needs a distinct webhook mount and Rack environment key. Existing
`Flipper::Cloud.app(flipper, env_key:)` already accepts an explicit instance and can
be reused. Automatic Rails mounting, if provided, must reject duplicate paths and
must leave the existing `/_flipper` route unchanged.

Polling and telemetry should continue to deduplicate by Cloud URL and token. Audit
fork behavior with two Cloud instances. If instrumentation needs instance identity,
add it only for named events; preserve the shape of default events.

### Active Record schema lifecycle

The default and named adapters may share a database connection, but they must not
share table names. For example:

```ruby
product_adapter = Flipper::Adapters::ActiveRecord.new
cross_app_adapter = Flipper::Adapters::ActiveRecord.new(table_prefix: "cross_app_")
```

The adapter creates isolated internal model subclasses for a prefix, so configuring
one adapter must not mutate the table names used by another adapter. Keep the
existing regression coverage for that property.

Applications own these tables through Rails migrations. They should generate the
named schema with the same prefix used by the adapter:

```shell
bin/rails generate flipper:active_record --table-prefix=cross_app_
```

When a future Flipper release changes the expected schema, the application must run
the Flipper update generator once for every table set, including the prefix:

```shell
bin/rails generate flipper:update
bin/rails generate flipper:update --table-prefix=cross_app_
```

This is how prefixed tables keep the same columns, indexes, and types as the default
tables. Named instances should not perform runtime schema creation or mutation.

### UI, API, and CLI

The UI and API already accept an explicit Flipper object and environment key. They
should work with a named proxy after their global group validation is changed to use
the supplied instance. Applications can mount separate UIs/APIs deliberately rather
than receiving automatic routes.

The CLI should continue to target the default instance. A future `--instance NAME`
option can be considered separately and is not required for the first release.

### Tests

`Flipper::TestHelp` must keep its current default behavior. Add named helpers or
configuration hooks that allow a named Cloud instance to use shared in-memory storage
during tests and clear its features between examples.

Per-example reset should preserve boot-time named group definitions, just as the
existing helper preserves global groups. Full configuration replacement must reset
the named group registry, thread-local DSLs, generated accessors, and retained proxy
resolution. Loading test help must not contact Cloud.

## Expected Code Surface

The repository audit found named-instance assumptions in more than the top-level
delegation layer. The likely implementation surface is:

- registry and access: `lib/flipper.rb`, `lib/flipper/configuration.rb`, and new
  proxy/configuration classes;
- ownership propagation: `lib/flipper/dsl.rb`, `lib/flipper/feature.rb`,
  `lib/flipper/feature_check_context.rb`, `lib/flipper/gates/group.rb`,
  `lib/flipper/types/group.rb`, and `lib/flipper/expressions/feature_enabled.rb`;
- Rails lifecycle: `lib/flipper/engine.rb`, `SetupEnv`, and `Memoizer` integration;
- Cloud: configuration, middleware group reporting, and routes;
- UI/API: group-gate validation against the supplied instance rather than global
  `Flipper`; and
- test support plus core, Rails, Cloud, UI, API, generator, thread, and fork specs.

This inventory should be re-run during implementation. It is a guard against
shipping an accessor that appears to work for booleans and actors while groups,
expressions, webhooks, or tests still fall back to the default instance.

## Implementation Phases

### 1. Core registry and access

- Add named child configurations, registry, proxy, and explicit accessors.
- Validate names and collisions.
- Add per-thread lifecycle and reset behavior.
- Verify the complete existing top-level API remains unchanged.

### 2. Instance-owned evaluation

- Add isolated group registries while preserving the live default global registry.
- Make group gates, feature helpers, and type wrapping owner-aware.
- Make feature expressions owner-aware and fix circular-evaluation identity.
- Update UI, API, and Cloud group lookups.

### 3. Rails integration

- Define named Rails settings and inheritance rules.
- Install paired setup/memoizer middleware only for configured names.
- Verify independent preloading and memoization for default plus multiple names.
- Apply strict, actor-limit, and instrumentation configuration consistently.

### 4. Cloud integration

- Require unambiguous per-name credentials.
- Support distinct webhook mounts and environment keys.
- Verify sync, polling, telemetry, and fork behavior with two projects.

### 5. Test support and documentation

- Add named test configuration/reset helpers without changing existing helpers.
- Document Active Record prefixes and migrations for each named local store.
- Document shared actor ID and group-definition requirements across applications.
- Add a complete Rails example with product and cross-product Cloud projects.

## Verification Matrix

At minimum, cover:

- zero named instances: all existing tests and public API behavior are unchanged;
- existing method arities, return values, custom `Flipper.configuration=` objects,
  and direct `Flipper.instance=` overrides remain compatible;
- default plus one and multiple named instances in one process;
- separate adapters and Active Record table prefixes do not overwrite one another;
- create and update generators apply the same schema changes to prefixed tables;
- same feature name has independent state in each instance;
- same group name can have independent predicates in each instance;
- late default global group registration still works;
- a named `feature_enabled` expression resolves only within its owner;
- retained proxy constants follow configuration replacement;
- name collisions, duplicates, invalid names, and configuration clearing;
- isolation between request threads and correct visibility of boot-time groups;
- default and named request memoization/preload independently start and stop;
- exceptions cannot leave either instance memoizing;
- distinct Cloud tokens, sync secrets, webhooks, and Rack environment keys;
- no Cloud network activity from test helpers;
- UI/API operations and group validation use the supplied instance; and
- supported Ruby and Rails versions through the repository's existing test matrix.

## Decisions

1. Configure a child with `config.named(:cross_app)`. Do not add arguments to
   `Flipper.configure`; even an optional argument changes its reflected arity and
   weakens the compatibility guarantee.
2. Access a child through both `Flipper.named(:cross_app)` and the explicitly defined
   `Flipper.cross_app` convenience method.
3. Inherit app-wide Rails instrumenter, strict mode, actor limit, memoize, and preload
   settings, while permitting named overrides. Credentials, Rack environment keys,
   and webhook paths are always instance-specific.
4. Automatically mount a named Cloud webhook only when that instance has a webhook
   path and sync secret configured.
5. Register groups through the named proxy, such as
   `Flipper.cross_app.register(:beta)`. Registration updates the configuration-owned
   group registry shared by every thread-local DSL for that name.
6. `Flipper::TestHelp` replaces every configured named adapter with a separate shared
   Memory adapter and preserves registered groups between examples.
7. Named Rails instances must be declared during initialization to receive automatic
   middleware and routes. A later core registration remains usable but requires
   explicit application middleware and route mounts.
8. Named instances are adapter-agnostic core functionality. A name opts into Cloud
   explicitly; Cloud environment variables do not implicitly create names.

The implementation includes group ownership, configuration reset, and independent
Rails memoization/preload behavior so those constraints are part of the public API
review rather than deferred follow-up work.
