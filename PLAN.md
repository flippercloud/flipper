# Controls: Local Adapter Storage Plan

Controls follow the same adapter pattern as features. Features have gate values stored via adapters; controls have control expressions stored via adapters. Sync brings remote controls into local storage, same as it does for features.

## Core Concepts

| Feature concept | Control equivalent |
|---|---|
| `features` → Set of keys | `controls` → Set of keys |
| `get(feature)` → gate values hash | `get_control(control)` → control values hash |
| `get_all` → all features + gate values | `get_all_controls` → all controls + values |
| `add(feature)` | `add_control(control)` |
| `remove(feature)` | `remove_control(control)` |
| `enable(feature, gate, thing)` / `disable(...)` | `set_control(control, expression)` / `clear_control(control)` |
| `GateValues` | `ControlValues` |
| `default_config` | `default_control_config` |

Key difference: no gates. A feature has 6 gates with enable/disable semantics. A control has one expression. So the adapter interface is simpler — `set_control` and `clear_control` instead of gate-mediated `enable`/`disable`.

## 1. ControlValues (`lib/flipper/control_values.rb`)

Parallel to `GateValues`. Wraps the raw adapter hash into a typed object for comparison during sync.

```ruby
class Flipper::ControlValues
  attr_reader :expression

  def initialize(adapter_values)
    @expression = adapter_values[:expression]
  end

  def eql?(other)
    self.class.eql?(other.class) &&
      expression == other.expression
  end
  alias_method :==, :eql?
end
```

Intentionally minimal. If controls later need a default value, description, or metadata, the hash and this class grow — same pattern as `GateValues`.

## 2. Adapter Interface (`lib/flipper/adapter.rb`)

Add `default_control_config` and default implementations for control methods, mirroring the feature defaults.

```ruby
module Flipper::Adapter
  module ClassMethods
    def default_control_config
      { expression: nil }
    end
  end

  def default_control_config
    self.class.default_control_config
  end

  def get_all_controls(**kwargs)
    result = {}
    controls.each do |key|
      control = Control.new(key, self)
      result[control.key] = get_control(control)
    end
    result
  end
end
```

Every adapter must implement: `controls`, `get_control`, `add_control`, `remove_control`, `set_control`, `clear_control`. `get_all_controls` has a default implementation (like `get_all` does for features).

## 3. Memory Adapter (`lib/flipper/adapters/memory.rb`)

Reference implementation. Add `@controls` hash alongside `@source`.

```ruby
def initialize(source = nil, threadsafe: true)
  @source = Typecast.features_hash(source)
  @controls = {}
  @lock = Mutex.new if threadsafe
  reset
end

def controls
  synchronize { @controls.keys }.to_set
end

def get_control(control)
  synchronize { @controls[control.key] } || default_control_config
end

def get_all_controls(**kwargs)
  synchronize { @controls.dup }
end

def add_control(control)
  synchronize { @controls[control.key] ||= default_control_config }
  true
end

def remove_control(control)
  synchronize { @controls.delete(control.key) }
  true
end

def set_control(control, expression_value)
  synchronize do
    @controls[control.key] ||= default_control_config
    @controls[control.key][:expression] = expression_value
  end
  true
end

def clear_control(control)
  synchronize { @controls[control.key] = default_control_config }
  true
end
```

Same threading pattern (`synchronize`), same `||= default_config` convention, same return-true pattern.

## 4. DualWrite Adapter (`lib/flipper/adapters/dual_write.rb`)

Reads from local, writes to remote then local. Same pattern as features.

```ruby
# Reads
def controls          = @local.controls
def get_control(c)    = @local.get_control(c)
def get_all_controls(**kwargs) = @local.get_all_controls(**kwargs)

# Writes
def add_control(c)
  @remote.add_control(c).tap { @local.add_control(c) }
end

def remove_control(c)
  @remote.remove_control(c).tap { @local.remove_control(c) }
end

def set_control(c, expr)
  @remote.set_control(c, expr).tap { @local.set_control(c, expr) }
end

def clear_control(c)
  @remote.clear_control(c).tap { @local.clear_control(c) }
end
```

## 5. Synchronizer (`lib/flipper/adapters/sync/synchronizer.rb`)

Extend `sync` to also sync controls. Independent from feature sync.

```ruby
def sync
  sync_features    # existing
  sync_controls    # new
end

def sync_controls
  local_controls = @local.get_all_controls
  remote_controls = @remote.get_all_controls(cache_bust: @cache_bust)

  # Sync changed controls
  remote_controls.each do |key, remote_values|
    local_values = local_controls.key?(key) ?
      local_controls[key] : @local.default_control_config
    local_cv = ControlValues.new(local_values)
    remote_cv = ControlValues.new(remote_values)
    next if local_cv == remote_cv

    control = Control.new(key, @local, instrumenter: @instrumenter)
    if remote_cv.expression.nil?
      @local.clear_control(control)
    else
      @local.set_control(control, remote_cv.expression)
    end
  end

  # Add missing
  to_add = remote_controls.keys - local_controls.keys
  to_add.each { |k| Control.new(k, @local, instrumenter: @instrumenter).add_control }

  # Remove extra
  to_remove = local_controls.keys - remote_controls.keys
  to_remove.each { |k| Control.new(k, @local, instrumenter: @instrumenter).remove_control }
end
```

## 6. Poll Adapter (`lib/flipper/adapters/poll.rb`)

Controls sync piggybacked on the existing sync mechanism. When the poller syncs, the Synchronizer now handles both features and controls in one pass.

## 7. HTTP Adapter (`lib/flipper/adapters/http.rb`)

Add control methods that hit the server API. Version support for incremental sync.

```ruby
def controls
  response = @client.get('/controls')
  raise Error, response unless response.is_a?(Net::HTTPOK)
  parsed = Typecast.from_json(response.body)
  parsed['controls'].map { |c| c['key'] }.to_set
end

def get_all_controls(cache_bust: false)
  path = "/controls"
  path += "?_cb=#{Time.now.to_i}" if cache_bust
  # ETag caching same pattern as get_all for features
  response = @client.get(path)
  raise Error, response unless response.is_a?(Net::HTTPOK)

  parsed = Typecast.from_json(response.body)
  result = {}
  (parsed['controls'] || []).each do |control_data|
    result[control_data['key']] = { expression: control_data['expression'] }
  end
  result
end

def set_control(control, expression)
  body = Typecast.to_json({ expression: expression })
  response = @client.put("/controls/#{control.key}", body)
  raise Error, response unless response.is_a?(Net::HTTPOK)
  true
end
```

## 8. Version Tracking (Optional Optimization)

The adapter can store a sync version. Two layers of caching:

1. **ETag** — "has anything changed?" (HTTP-level, zero-cost 304)
2. **Version/since** — "what changed since version N?" (app-level, only deltas transferred)

The version lives on the local adapter, gets set after each sync. On next sync, client sends `?since=N`, server returns only deltas. Full resync is the fallback if client has no version or is too far behind.

```ruby
# On local adapter
attr_accessor :controls_version

# In sync_controls
if (version = remote_response[:version])
  @local.controls_version = version
end
```

This is an optimization that can be added later without changing the core interface.

## Implementation Order

1. `ControlValues` — standalone, no dependencies
2. `Adapter` module — add `default_control_config` and default `get_all_controls`
3. `Memory` adapter — reference implementation, enables testing everything else
4. `DualWrite` adapter — reads local, writes both
5. `Synchronizer` — extend to sync controls alongside features
6. `HTTP` adapter — server communication for controls
7. `Poll` adapter — inherits sync behavior automatically through Synchronizer
8. Version tracking — optimization, can be deferred

## Files to Create

- `lib/flipper/control_values.rb`
- `spec/flipper/control_values_spec.rb`

## Files to Modify

- `lib/flipper/adapter.rb` — add `default_control_config`, `get_all_controls`
- `lib/flipper/adapters/memory.rb` — add `@controls` and all control methods
- `lib/flipper/adapters/dual_write.rb` — add control delegation methods
- `lib/flipper/adapters/sync/synchronizer.rb` — add `sync_controls`
- `lib/flipper/adapters/http.rb` — add control API methods
- `lib/flipper/adapters/poll.rb` — should work automatically via Synchronizer
- Shared adapter specs — add control method specs to ensure consistency across backends
