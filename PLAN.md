# Controls Plan

Controls are named expressions that return a value (string, number, boolean) instead of true/false. They sit next to features rather than inside them. Features answer "is this on?" through gates. Controls answer "what should this be?" with a single expression. Both use the same expression engine, the same adapters, and the same sync path.

```ruby
Flipper.enabled?(:new_checkout, user)                          # feature → true/false
Flipper.value(:checkout_variant, user, default: "control")     # control → "variant_a"
Flipper.control(:rate_limit).value(user, default: 1_000)       # control → 10_000
```

## Decisions so far

- **Controls are separate from features.** Gates combine by OR to produce a boolean, and a value expression doesn't take part in that. A separate concept keeps `enabled?`, `state`, the gates, the UI, and the API unchanged.
- **Lisp-style implicit return.** An expression returns whatever its taken branch evaluates to. Controls don't declare a type. The call site provides `default:` for nil or no match.
- **Storage mirrors features.** Controls get their own adapter methods and their own `ControlValues` (the counterpart of `GateValues`). Local adapters store them, and sync writes them locally the same way it does features.
- **Version tracking is optional.** It's an HTTP-level optimization layered on top of a full-set contract (see §7).

---

## 1. Public API

### `Flipper::Control` (`lib/flipper/control.rb`)

The counterpart of `Feature`, without gates or state.

```ruby
class Flipper::Control
  InstrumentationName = "control_operation.#{InstrumentationNamespace}".freeze

  attr_reader :name, :key, :adapter, :instrumenter

  def initialize(name, adapter, options = {})
    @name = name
    @key = name.to_s
    @adapter = adapter
    @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
  end

  # Accepts a Flipper::Expression or the equivalent Hash.
  def set(expression)
    instrument(:set) do
      adapter.add_control(self)
      adapter.set_control(self, Expression.build(expression).value)
    end
  end

  def clear  = instrument(:clear)  { adapter.clear_control(self) }
  def add    = instrument(:add)    { adapter.add_control(self) }
  def remove = instrument(:remove) { adapter.remove_control(self) }
  def exist? = instrument(:exist?) { adapter.controls.include?(key) }

  def expression
    data = values.expression
    Expression.build(data) if data
  end

  def values
    ControlValues.new(adapter.get_control(self))
  end

  # Single actor (not *actors). A value has no sensible way to combine
  # results from several actors, unlike enabled?'s any?.
  def value(actor = nil, default: nil)
    instrument(:value, actor: actor) do |payload|
      result = expression&.evaluate(Expression::Context.build(key, actor))
      payload[:result] = result.nil? ? default : result
    end
  end
end
```

### DSL (`lib/flipper/dsl.rb`) and `Flipper` module

```ruby
def control(name)                                   # memoized like #feature
def value(name, actor = nil, default: nil) = control(name).value(actor, default: default)
def set_control(name, expression)          = control(name).set(expression)
def clear_control(name)                    = control(name).clear
def controls                               # Set of Control instances
```

Add these to the `Flipper` module's `def_delegators` list as well.

### Shared evaluation context (`lib/flipper/expression/context.rb`)

`Gates::Expression#properties` currently builds the `{feature_name:, properties:, actor:}` context. Extract it so features and controls share it:

```ruby
Expression::Context.build(name, actor) # => { feature_name: name, properties: {...}, actor: actor }
```

The control key goes into `feature_name` on purpose: `PercentageOfActors` seeds its hash with `context[:feature_name]`, so percentage splits stay stable per control. The context key keeps the name `feature_name` so existing expressions keep working.

---

## 2. Expression additions

Two engine facts shape these nodes:

1. **`Expression.build` can't build Arrays.** It only accepts Hash, String, Numeric, Boolean, and Symbol. Nested pairs like `[[cond, val], ...]` won't parse, so **use flat arguments**, the same way Clojure's `cond` does.
2. **`Expression#evaluate` is eager.** It evaluates every argument before calling the function, so every branch runs even when it isn't taken. This is fine for pure nodes. It's wasteful (or surprising) for `Random` and `FeatureEnabled`. **Add lazy evaluation for conditional nodes.** If a function declares `lazy: true`, `evaluate` passes it unevaluated args plus the context, and the function evaluates only the branches it needs.

```ruby
# lib/flipper/expressions/if_else.rb  →  {"IfElse": [cond, then, else]}
# lib/flipper/expressions/cond.rb     →  {"Cond": [c1, v1, c2, v2, ..., default?]}
#   pairs are evaluated in order; an odd trailing arg is the default; no match → nil
```

Builder helpers: `Flipper.if_else(cond, a, b)` and `Flipper.cond(c1, v1, c2, v2, default)`.

**Limitation:** Hashes always build as function calls, so a branch can't return a literal Hash or Array (for example, a JSON config blob). v1 supports scalar return values only. If structured values are needed later, add a `Literal` node (`{"Literal": [{...}]}`).

Because `!!` still applies in the feature gate, `IfElse` and `Cond` also work inside feature expressions.

---

## 3. Storage contract

### `ControlValues` (`lib/flipper/control_values.rb`)

```ruby
class Flipper::ControlValues
  attr_reader :expression

  def initialize(adapter_values)
    @expression = adapter_values[:expression]
  end

  def eql?(other)
    self.class.eql?(other.class) && expression == other.expression
  end
  alias_method :==, :eql?
end
```

### Adapter interface (`lib/flipper/adapter.rb`)

| Feature | Control |
|---|---|
| `features` | `controls` → Set of keys |
| `get(feature)` | `get_control(control)` → `{expression: Hash \| nil}` |
| `get_multi(features)` | `get_multi_controls(controls)` |
| `get_all` | `get_all_controls(**kwargs)` |
| `add` / `remove` / `clear` | `add_control` / `remove_control` / `clear_control` |
| `enable` / `disable` (via gates) | `set_control(control, expression_hash)` |
| `default_config` | `default_control_config` → `{expression: nil}` |

`set_control` receives the raw serialized Hash (`expression.value`). It never receives an `Expression` object, so adapters only ever deal with JSON-able data.

### Opt-in capability (avoid breaking existing adapters)

Adding required methods would break every adapter in and outside this repo (Rollout, Moneta, Mongo, third-party adapters). Use a capability flag instead:

```ruby
module Flipper::Adapter
  class ControlsNotSupported < Flipper::Error; end

  def supports_controls? = false
  def controls           = Set.new
  def get_control(_)     = default_control_config
  def get_multi_controls(cs) = cs.each_with_object({}) { |c, h| h[c.key] = get_control(c) }
  def get_all_controls(**) = get_multi_controls(controls.map { |k| Control.new(k, self) })
  %i[add_control remove_control clear_control set_control].each do |m|
    define_method(m) { |*| raise ControlsNotSupported, "#{name} adapter does not support controls" }
  end
end
```

Reads return empty and writes raise. Adapters that implement controls override `supports_controls?` to return true.

---

## 4. Adapter changes

### Must-have (the Cloud path: `dual_write(local: poll(memory), remote: http)` plus DSL wrappers)

- **Memory**
  - Add `@controls`, all control methods, and `supports_controls? = true`.
  - Have `get_all_controls` and `get_control` return **deep copies** so callers can't mutate stored state. A plain `@controls.dup` leaves the inner hashes shared.
  - Extend the constructor to `Memory.new(source = nil, controls: nil, threadsafe: true)` so `Export#adapter` can seed controls.
  - **Fix `import`.** `Memory#import` bypasses the Synchronizer and calls `@source.replace(adapter.get_all)`. That's exactly what the Poller calls (`@adapter.import @remote_adapter`), so as written controls would never reach local storage. It also has to replace `@controls` with `adapter.get_all_controls`, but only when `adapter.supports_controls?`. Otherwise it must leave local controls untouched.
- **Wrapper**
  - Add the control methods and `supports_controls?` to `METHODS`. That covers ActorLimit, OperationLogger, ReadOnly, and Strict automatically.
  - **ReadOnly** must raise on the control write methods.
  - **Strict** must check `controls` for control reads.
- **Memoizable**
  - Cache `get_control` and `get_all_controls` under a separate key namespace (`control/<key>`, `controls`, `get_all_controls`).
  - Expire on control writes and clear on `import`.
  - Without this, every `Flipper.value` call reads the adapter. That costs nothing in memory but means a query per call with ActiveRecord.
- **DualWrite**: reads go local; writes go remote first, then local.
- **Poll**
  - `def_delegators` lists methods explicitly, so add the control methods there. This isn't automatic.
  - The initial blocking sync checks `adapter.features.empty?`. Extend it to `&& adapter.controls.empty?` so an app with only controls still syncs at boot.
- **Sync** adapter (`lib/flipper/adapters/sync.rb`): same delegation as Poll.
- **Instrumented, Failover, Failsafe, CacheBase**: each overrides methods explicitly, so each needs control methods added.
  - Failsafe returns empty or default on error.
  - CacheBase caches `get_all_controls` under its own key.
- **HTTP**: see §7.

### Later (persistent local storage)

- **ActiveRecord**: a new `flipper_controls` table (`key` unique, `expression` text/json, timestamps), plus a generator migration. Don't reuse `flipper_gates`.
- **Redis**: a `flipper_controls` set of keys plus a `flipper_control:<key>` hash. Use a prefix that can't collide with feature keys.
- **Sequel, Mongo, PStore, Moneta**: implement when asked. Until then they report `supports_controls? = false`.

---

## 5. Sync (`lib/flipper/adapters/sync/synchronizer.rb`)

Add a `sync_controls` step and a `ControlSynchronizer` alongside `FeatureSynchronizer`:

```ruby
def sync
  sync_features
  sync_controls if @local.supports_controls? && @remote.supports_controls?
end

def sync_controls
  local  = @local.get_all_controls
  remote = @remote.get_all_controls(cache_bust: @cache_bust)

  remote.each do |key, remote_hash|
    control = Control.new(key, @local, instrumenter: @instrumenter)
    local_hash = local.key?(key) ? local[key] : @local.default_control_config
    ControlSynchronizer.new(control, ControlValues.new(local_hash), ControlValues.new(remote_hash)).call
  end

  (remote.keys - local.keys).each { |k| Control.new(k, @local, instrumenter: @instrumenter).add }
  (local.keys - remote.keys).each { |k| Control.new(k, @local, instrumenter: @instrumenter).remove }
end
```

```ruby
class ControlSynchronizer
  def call
    return if @local_values == @remote_values
    @remote_values.expression.nil? ? @control.clear : @control.set(@remote_values.expression)
  end
end
```

**Invariant:** `get_all_controls` **always returns the complete set**. The remove step depends on it: a delta-only response would delete every unchanged control. Any incremental fetching stays hidden inside the HTTP adapter (§7).

---

## 6. Export / import

- **`Exporters::Json::V1`**: add `"controls": { key => { "expression": ... } }` next to `"features"`, but only when `adapter.supports_controls?`. This is additive, so v1 readers that ignore unknown keys keep working. Confirm the Cloud `/import` endpoint ignores or accepts the key before shipping.
- **`Exporters::Json::Export`**: add a `#controls` reader (default `{}` when the key is missing). `Export#adapter` passes it to `Memory.new(features, controls: controls)`.
- **`Export#adapter`** must report `supports_controls?` only when the export actually has a `controls` key. Otherwise importing an old export would wipe local controls.
- **HTTP#import**, **Cloud migrate/push**: these already send `export.contents`, so they pick up controls for free.

---

## 7. HTTP adapter and Cloud protocol

### Client methods

`controls`, `get_control`, `get_all_controls(cache_bust:)`, `add_control`, `remove_control`, `set_control`, `clear_control`. Use `Typecast.to_json`/`from_json` and the existing `Client`.

### Endpoints the Cloud and API need

| Method | Path | Purpose |
|---|---|---|
| GET | `/controls` | All controls `{controls: [{key, expression}], version}` (ETag) |
| GET | `/controls?since=N` | Deltas `{controls: [...], removed: [...], version, incremental: true}` |
| GET | `/controls/:key` | One control |
| POST | `/controls` | Add `{name}` |
| PUT | `/controls/:key` | Set `{expression}` |
| DELETE | `/controls/:key/expression` | Clear |
| DELETE | `/controls/:key` | Remove |

### `supports_controls?` on HTTP

Return true by default. If `/controls` returns 404 (older server or self-hosted `flipper-api` without controls), **raise or treat it as unsupported. Never return `{}`.** An empty result would make the Synchronizer remove every local control.

### Version and incremental sync

The version lives **in the HTTP adapter**, next to `@last_get_all_etag`. It does not live in the local adapter.

- The HTTP adapter keeps the last full result in memory and applies deltas from `?since=N` to it. It always hands the Synchronizer a full set.
- A process restart drops the in-memory version, so the first request is a full fetch. That's correct and simple.
- The server can answer `?since=N` with a full payload (no `incremental: true`) whenever N is too old. The client then replaces its cache.

Two cache layers stack:

1. ETag: nothing changed, so the server returns 304.
2. `since`: a few things changed, so the server sends only those.

Persisting the version in the **local** adapter only pays off when the local adapter is persistent (ActiveRecord or Redis) and the process should skip the full fetch at boot. That needs the HTTP adapter to be seeded from local state. Defer it until ActiveRecord or Redis support controls.

### Poll cadence

The Poller calls `@adapter.import(@remote_adapter)`, which now issues two GETs per cycle (`/features` and `/controls`). Both carry ETags, so the steady state is two 304s. If that turns out to matter, a combined endpoint can come later.

### Webhook

`Cloud::Middleware` already calls `flipper.sync(cache_bust: true)`. Once the Synchronizer handles controls, a control change on Cloud reaches the app through the same webhook. No middleware changes are needed.

---

## 8. API / UI (follow-up, not required for v1)

- `flipper-api`: `lib/flipper/api/v1/actions/controls.rb`, `control.rb`, and a decorator, matching the endpoints above. This is what makes the HTTP adapter work against self-hosted setups.
- `flipper-ui`: a separate "Controls" section that lists keys and shows and edits the expression JSON. Don't put it on feature pages.

---

## 9. Open questions

- **Naming**: `Flipper.value(:x, user)` vs only `Flipper.control(:x).value(user)`. `value` is a generic name on the top-level module, so maybe ship only `control(...).value`.
- **Default stored on the control?** The plan currently keeps `default:` at the call site only. Storing one in `default_control_config` would let Cloud change it, but it adds a second source of truth.
- **`FeatureEnabled` inside a control** uses `context[:feature_name]` for cycle detection. A control and a feature with the same key could look like a cycle. Rename the context key to `:flag_name`, or namespace control keys in the context.
- **Return-type validation**: none in v1 (Lisp-style). Cloud UI could warn when branches return mixed types.

---

## 10. Implementation order

Each step lands with specs. The order is RSpec first, then shared adapter specs.

1. **Expression engine**: lazy evaluation, `IfElse`, `Cond`, builder helpers, `Expression::Context` extraction (`Gates::Expression` uses it, so feature behavior is unchanged).
2. **`ControlValues`, `Control`, DSL and `Flipper` delegators.**
3. **Adapter module**: `supports_controls?`, read defaults, write methods that raise, `default_control_config`.
4. **Shared spec**: `spec/support/shared_controls_adapter_specs.rb` (`it_should_behave_like "a flipper controls adapter"`). Include it from every adapter that sets `supports_controls? = true`.
5. **Memory**: methods, deep copies, constructor `controls:`, `import`.
6. **Wrappers**: Wrapper `METHODS`, ReadOnly, Strict, Memoizable, Instrumented, Failover, Failsafe, CacheBase.
7. **DualWrite, Poll, Sync adapter delegation.**
8. **Synchronizer** plus `ControlSynchronizer`, including the "unsupported remote/local skips sync" and "old export doesn't wipe controls" cases.
9. **Export/import**: the V1 exporter `controls` key, `Export#controls`, and the round-trip spec.
10. **HTTP adapter**: full fetch with ETag, then `since` and delta merging, and 404 → unsupported.
11. **flipper-api endpoints** (needed for HTTP adapter specs against a real Rack app).
12. **Later**: ActiveRecord (table plus generator), Redis, UI, and persisting the version locally.

## Files

**New**
- `lib/flipper/control.rb`, `lib/flipper/control_values.rb`
- `lib/flipper/expression/context.rb`
- `lib/flipper/expressions/if_else.rb`, `lib/flipper/expressions/cond.rb`
- `lib/flipper/adapters/sync/control_synchronizer.rb`
- `spec/support/shared_controls_adapter_specs.rb` plus matching specs for each new class

**Modified**
- `lib/flipper.rb`, `lib/flipper/dsl.rb`
- `lib/flipper/expression.rb` (lazy eval), `lib/flipper/expression/builder.rb`, `lib/flipper/gates/expression.rb`
- `lib/flipper/adapter.rb`
- `lib/flipper/adapters/{memory,wrapper,read_only,strict,memoizable,dual_write,poll,sync,instrumented,failover,failsafe,cache_base,http}.rb`
- `lib/flipper/adapters/sync/synchronizer.rb`
- `lib/flipper/export.rb`, `lib/flipper/exporters/json/{v1,export}.rb`
