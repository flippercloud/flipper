# Flipper Security, Correctness & Concurrency Audit

**Date:** 2026-07-06
**Scope:** `lib/` — core library, storage adapters, UI, API, middleware, and Flipper Cloud.
**Method:** Static source review across five focus areas (UI/API security, threading/concurrency, core correctness, storage adapters, cloud/CLI). Every finding below was re-verified against the source by reading the cited lines.

> **Context on Flipper's threat model.** The UI and API middleware intentionally ship **without** authentication — the host application is expected to protect the mount point. Several findings are only reachable when that mounting is misconfigured (public mount, weak auth). They are still worth fixing because misconfiguration is common and cheap to defend against. Similarly, Flipper's primary API is per-thread (`Flipper.enabled?` uses a per-thread instance), so several concurrency bugs only surface when a single `Flipper`/adapter instance is deliberately shared across threads (a documented, common pattern like `$flipper = Flipper.new(adapter)`) or in fork-based servers.

---

## Severity Summary

| # | Severity | Category | Issue | Location |
|---|----------|----------|-------|----------|
| 1 | **High** | Security (XSS) | Stored HTML/XSS via unescaped actor identifiers on the dashboard | `ui/decorators/feature.rb:44,48` + `ui/views/features.erb:52` |
| 2 | **High** | Threading | Fork-time `Mutex#unlock` of a foreign mutex raises `ThreadError` in the fork-recovery path | `adapters/memory.rb:125-141`, `poller.rb:133-137` |
| 3 | **Medium** | Security (CSRF) | Authenticity-token check silently dropped when any `rack_protection` option is passed | `ui.rb:37-41` |
| 4 | **Medium** | Correctness | `race_condition_ttl` cache option is a silent no-op | `adapters/active_support_cache_store.rb:83` |
| 5 | **Medium** | Correctness | Comparison expressions raise `ArgumentError` on type-mismatched operands | `expressions/comparable.rb:8` |
| 6 | **Medium** | Security | Webhook replay: signature timestamp tolerance never enforced | `cloud/middleware.rb:36`, `cloud/message_verifier.rb:46` |
| 7 | **Medium** | Reliability | Failover/Failsafe swallow the entire `StandardError` hierarchy by default | `adapters/failsafe.rb:14`, `adapters/failover.rb:23` |
| 8 | **Medium** | Security | Cloud auth token leaked to STDOUT/logs when debug output is enabled | `cloud/configuration.rb:191-202`, `adapters/http/client.rb:94` |
| 9 | **Medium** | Threading | Non-atomic sync gates cause thundering-herd concurrent syncs (`Poll` + `IntervalSynchronizer`) | `adapters/poll.rb:41-49`, `adapters/sync/interval_synchronizer.rb:27-41` |
| 10 | **Medium** | Threading | Shared DSL `@memoized_features` / Memoizable `@cache` mutated concurrently | `dsl.rb:221`, `adapters/memoizable.rb` |
| 11 | **Medium** | Threading | Cloud telemetry reassigns `@metric_storage`/`@pool`/`@timer` without synchronization | `cloud/telemetry.rb:63-118` |
| 12 | **Low** | Correctness | AR migration warning can never fire (inverted memoization guard) | `adapters/active_record.rb:300-303` |
| 13 | **Low** | Correctness | JSON exporter mutates adapter-owned hash in place | `exporters/json/v1.rb:14-20` |
| 14 | **Low** | Data integrity | Moneta adapter non-atomic read-modify-write → lost updates | `adapters/moneta.rb` (`enable`/`disable`/`add`/`remove`) |
| 15 | **Low** | Data integrity | Failover dual-write is non-atomic with no reconciliation | `adapters/failover.rb:54-82` |
| 16 | **Low** | Security | HTTP adapter interpolates feature/gate keys into URLs without escaping | `adapters/http.rb`, `adapters/http/client.rb` |
| 17 | **Low** | Security | `RedisCache` uses `Marshal.load` on cached blobs (RCE gadget sink) | `adapters/redis_cache.rb:23,35,42` |
| 18 | **Low** | Correctness | CRC32 modulo bias in percentage-of-actors bucketing | `gates/percentage_of_actors.rb:33` |
| 19 | **Low** | Reliability | `Poller#stop` uses `Thread#kill` (abrupt, self-kill from sync path) | `poller.rb:55-60` |
| 20 | **Low** | Threading | `Flipper.configuration` / `groups_registry` lazy init is racy at boot | `flipper.rb:29,182` |
| 21 | **Low** | Reliability | CLI auto-opens a server-controlled URL without confirmation | `cli.rb:102-106` |
| 22 | **Low** | Security | Cleartext token transmission if Cloud URL configured as `http://` | `adapters/http/client.rb:96-99` |
| 23 | **Low** | Robustness | Import endpoints: unbounded input + unguarded param access | `ui/actions/import.rb:12`, `api/v1/actions/import.rb:16` |
| 24 | **Info** | Correctness | Multi-actor percentage-of-actors hashes the concatenation of all actors | `gates/percentage_of_actors.rb:33` |
| 25 | **Info** | Various | Minor items: `Typecast.to_set` on scalars, `FeatureEnabled` cleanup bookkeeping, `uri_for_path` leading `&`, gzip has no size cap, webhook error reflected in headers, `at_exit` accumulation, no built-in UI/API auth | see details |

---

## High Severity

### 1. Stored HTML / XSS via unescaped actor identifiers on the dashboard
**Files:** `lib/flipper/ui/decorators/feature.rb:44,48`; rendered raw at `lib/flipper/ui/views/features.erb:52`

`gates_in_words` hand-builds an HTML string and interpolates actor values straight into a `title` attribute with no escaping:

```ruby
statuses << %Q(<span data-toggle="tooltip" data-placement="bottom" title="#{Util.to_sentence(feature.actors_value.to_a)}">) + ...
```

and the view emits it **raw** (`<%==`, unescaped):

```erb
<%== feature.gates_in_words %>
```

Actor `flipper_id`s are free-form strings with no character restrictions and can be introduced by a lower-privilege user via the UI "Add Actor" form (`ui/actions/actors_gate.rb`), the API (`api/v1/actions/actors_gate.rb`), or an imported export file. An id like `x" onmouseover="alert(document.domain)` or `"><img src=x onerror=...>` is stored and then written unescaped into the dashboard for every admin who loads `/features` (the default landing page).

**Mitigating factor:** UI responses set a restrictive CSP (`ui/action.rb:39-48`, `script-src 'self'` with no `unsafe-inline`), which blocks injected inline scripts/handlers in modern browsers. This downgrades it from a clean JS-execution bug to HTML/CSS injection + content spoofing — but JS execution returns anywhere the CSP is stripped or weakened (reverse proxies, a host app that sets its own CSP, older browsers). The single-feature page renders the same data safely with `<%= %>` / `Sanitize.fragment`; only this list-page path is unescaped.

**Fix:** HTML-escape the interpolated actor values inside `gates_in_words` (e.g. `Rack::Utils.escape_html`), or return structured data and escape in the view instead of using `<%==`.

### 2. Fork-time `Mutex#unlock` of a foreign mutex raises `ThreadError`
**Files:** `lib/flipper/adapters/memory.rb:125-141`; `lib/flipper/poller.rb:133-137`

The fork-recovery code unlocks a mutex it may not own:

```ruby
def reset
  @pid = Process.pid
  @lock&.unlock if @lock&.locked?          # unlocking a mutex owned by a now-dead thread
end

def synchronize(&block)
  if @lock
    reset if forked?                        # runs OUTSIDE the lock
    @lock.synchronize(&block)
  ...
```

If a process forks (Puma/Unicorn/Resque preload-then-fork) while another thread holds the mutex, the child inherits a mutex flagged as locked by a thread that no longer exists. `locked?` returns `true`, and `unlock` from the surviving thread raises `ThreadError: Attempt to unlock a mutex which is locked by another thread` — a crash in the exact recovery path meant to prevent one. `memory.rb` has an additional TOCTOU: `reset` runs before the lock is acquired, so two threads in a fresh child can both call `reset` and the second `unlock` hits "not locked."

**Fix:** After a fork, **replace** the mutex rather than unlock it: `@lock = Mutex.new` (and `@mutex = Mutex.new` in the poller). A fresh mutex is the only safe post-fork state.

---

## Medium Severity

### 3. Authenticity-token CSRF check silently dropped when a `rack_protection` option is passed
**File:** `lib/flipper/ui.rb:37-41`

```ruby
if rack_protection_options.empty?
  builder.use Rack::Protection::AuthenticityToken   # form-token CSRF check
else
  builder.use Rack::Protection, rack_protection_options
end
```

The UI's forms all embed a CSRF token (`ui/action.rb` `csrf_input_tag`) whose validation depends on `Rack::Protection::AuthenticityToken`. But in rack-protection 3.x/4.x the bundled `Rack::Protection` middleware has `AuthenticityToken` **off by default**. So passing *any* non-empty `rack_protection:` option (e.g. `{ allow_if: ... }`) drops the token check entirely. The code comment ("go whole hog and include all of Rack::Protection") is factually wrong. Residual protections (`HttpOrigin`, `RemoteToken`, `JsonCsrf`) still block many cross-origin POSTs but fail open for requests lacking `Origin`/`Referer`.

**Fix:** Always include the token check, e.g. add `builder.use Rack::Protection::AuthenticityToken` unconditionally, or merge `use: [:authenticity_token, ...]` into the options path. Fix the comment.

### 4. `race_condition_ttl` cache option is a silent no-op
**File:** `lib/flipper/adapters/active_support_cache_store.rb:83`

```ruby
def write_options
  write_options = {}
  write_options[:expires_in] = @ttl if @ttl
  write_options[:race_condition_ttl] if @race_condition_ttl   # reads the key, never assigns
  write_options
end
```

Line 83 evaluates `write_options[:race_condition_ttl]` (nil) as a bare expression and never assigns anything. Users who configure `race_condition_ttl:` to guard against cache-stampede get **zero** protection, with no error or warning — defeating the exact race the option exists to prevent.

**Fix:** `write_options[:race_condition_ttl] = @race_condition_ttl if @race_condition_ttl`

### 5. Comparison expressions raise `ArgumentError` on type-mismatched operands
**File:** `lib/flipper/expressions/comparable.rb:8` (used by `greater_than`, `less_than`, `greater_than_or_equal_to`, `less_than_or_equal_to`)

```ruby
def self.call(left, right)
  left.respond_to?(operator) && right.respond_to?(operator) && left.public_send(operator, right)
end
```

The `respond_to?` guards confirm both sides respond to `>`/`<` etc., but **not** that they're type-compatible. Every `String` and every `Integer` responds to `>`, yet `"25" > 21` raises `ArgumentError: comparison of String with 21 failed`. Property values commonly arrive as strings from JSON, so an actor with `flipper_properties = { age: "25" }` checked against `Flipper.property(:age).gte(21)` raises out of `Feature#enabled?` — the whole flag check blows up instead of returning `false`. (Missing/`nil` properties are safe because `nil.respond_to?(:>=)` is false.)

**Fix:** Rescue `ArgumentError` and treat a failed comparison as `false`, or normalize operand types before comparing.

### 6. Webhook replay: signature timestamp tolerance never enforced
**Files:** `lib/flipper/cloud/middleware.rb:36`; `lib/flipper/cloud/message_verifier.rb:46`

The HMAC signature check itself is correct and timing-safe (SHA256 digest + constant-time compare in `secure_compare`), and the signed message includes the timestamp, so it can't be tampered. **But** the middleware never passes a `tolerance:`:

```ruby
if message_verifier.verify(payload, signature)   # tolerance defaults to nil → freshness check skipped
```

```ruby
def verify(payload, header, tolerance: nil)
  ...
  if tolerance && timestamp < Time.now - tolerance   # skipped entirely when tolerance is nil
```

A single captured, validly-signed webhook can be replayed by an unauthenticated caller indefinitely. Impact is bounded — each replay forces `flipper.sync(cache_bust: true)` — so this is a replay/amplification-DoS, not an integrity break.

**Fix:** Pass a tolerance from the middleware (`verify(payload, signature, tolerance: 60)`) and rescue the failure as a 400. Consider also rejecting timestamps too far in the future.

### 7. Failover/Failsafe swallow the entire `StandardError` hierarchy by default
**Files:** `lib/flipper/adapters/failsafe.rb:14`; `lib/flipper/adapters/failover.rb:23`

```ruby
@errors = options.fetch(:errors, [StandardError])
...
rescue *@errors
```

The default catches **everything** — `NoMethodError`, `TypeError`, `JSON::ParserError`, serialization bugs — not just connectivity failures. A genuine code/data bug in the primary adapter is silently masked: Failsafe returns `{}`/`Set.new`/`false` (which reads as "all features disabled" in production), and Failover quietly serves possibly-stale secondary data. The operator sees no error.

**Fix:** Default to a narrow connectivity-error list (timeouts, `Errno::ECONNREFUSED`, `Redis::BaseConnectionError`, etc.) and/or instrument every swallowed exception so failures stay observable.

### 8. Cloud auth token leaked to STDOUT/logs when debug output is enabled
**Files:** `lib/flipper/cloud/configuration.rb:191-202`; `lib/flipper/adapters/http/client.rb:94`

Enabling `FLIPPER_CLOUD_DEBUG_OUTPUT_STDOUT` (or `debug_output=`) hands the raw stream to `Net::HTTP#set_debug_output`, which dumps all request headers — including `flipper-cloud-token` (the environment's bearer credential) — in cleartext to logs. Requires operator opt-in, so it's a footgun rather than a default exposure, but an operator debugging a sync issue in production leaks the token to centralized logging.

**Fix:** Redact the `flipper-cloud-token` / `authorization` headers before handing the stream to `set_debug_output`, or loudly document that debug output exposes the token.

### 9. Non-atomic sync gates cause thundering-herd concurrent syncs
**Files:** `lib/flipper/adapters/poll.rb:41-49`; `lib/flipper/adapters/sync/interval_synchronizer.rb:27-41`

Both use an unsynchronized check-then-act on a plain ivar shared across all request threads:

```ruby
# interval_synchronizer.rb
def call
  return unless time_to_sync?     # reads @last_sync_at
  @last_sync_at = now             # plain ivar, no lock
  @synchronizer.call
end
```

After the interval elapses, N threads all see `time_to_sync?` true before any updates the timestamp, so **all N** run a full `Synchronizer#call` — each a remote `get_all` round-trip plus overlapping local writes. Defeats the interval limiting. Same pattern in `Poll#synced_adapter` (`@last_synced_at`).

**Fix:** Make the gate atomic — mutex around the read-check-set, or a `Concurrent::AtomicFixnum` with `compare_and_set` so exactly one thread wins per interval.

### 10. Shared DSL `@memoized_features` / Memoizable `@cache` mutated concurrently
**Files:** `lib/flipper/dsl.rb:221`; `lib/flipper/adapters/memoizable.rb`

```ruby
@memoized_features[name.to_sym] ||= Feature.new(name, @adapter, instrumenter: instrumenter)
```

Safe under the per-thread module API, but a shared `Flipper.new(adapter)` / `Flipper::Cloud.new` instance across threads (a supported, common pattern) mutates a plain `Hash` with a non-atomic `||=`. Concurrent insert during another thread's iteration raises `can't add a new key into hash during iteration` or loses writes. Memoizable's `@cache.fetch(k){ cache[k]=... }` has the same hazard when memoizing.

**Fix:** Back both with `Concurrent::Map` (`compute_if_absent` is atomic), or document that a DSL instance isn't safe to share across threads.

### 11. Cloud telemetry reassigns shared state without synchronization
**File:** `lib/flipper/cloud/telemetry.rb:63-118`

`record` (arbitrary app threads), `post_to_pool` (timer thread), and `post_to_cloud` (pool thread) all read `@metric_storage`/`@pool`/`@timer`, while `restart` (on fork) and `stop` (on a `telemetry-shutdown` header) reassign/tear them down with no lock. Races drop metrics (increment into a swapped-out storage; `@pool.post` onto a shutting-down pool discarded silently) and can observe an inconsistent storage/pool/timer trio.

**Fix:** Guard `start`/`stop`/`restart` and the reads with a mutex (or swap an `AtomicReference` atomically); at minimum snapshot `storage = @metric_storage` once per method.

---

## Low Severity

### 12. AR migration warning can never fire (inverted guard)
**File:** `lib/flipper/adapters/active_record.rb:300-303`

```ruby
def warned_about_value_not_text?
  return @warned_about_value_not_text if defined?(@warned_about_value_not_text)
  @warned_about_value_not_text = true      # returns true on the FIRST call
end
```

On the first call the ivar is undefined, so it falls through, sets `true`, and returns `true` — making `!warned_about_value_not_text?` false forever. The `VALUE_TO_TEXT_WARNING` telling users to run the JSON-column migration is permanently suppressed; they get no heads-up until a hard `raise` on a JSON write. **Fix:** return `false` the first time, flip to `true` after.

### 13. JSON exporter mutates adapter-owned hash in place
**File:** `lib/flipper/exporters/json/v1.rb:14-20`

```ruby
features = adapter.get_all
features.each do |feature_key, gates|
  gates.each do |key, value|
    features[feature_key][key] = value.to_a if value.is_a?(Set)   # mutates live adapter data
  end
end
```

The default `Adapter#get_all` returns references to internal storage for adapters whose `get` returns internal refs. Exporting then replaces stored `Set`s with `Array`s inside the adapter's live data, so a later actor-add does `array << value` and permits duplicates. The stock `Memory` adapter escapes this (it returns a fresh copy), but the documented default path is unsafe. **Fix:** build a new structure with `transform_values` instead of mutating.

### 14. Moneta adapter non-atomic read-modify-write → lost updates
**File:** `lib/flipper/adapters/moneta.rb` (`enable`/`disable`/`add`/`remove`)

Unlike Mongo (`$addToSet`/`$pull`) and Redis (`hset`/`hdel`), Moneta does full read → mutate-in-Ruby → write-back with no lock. Two concurrent `enable`s for actors A and B on the same feature both read the same set, each adds one, each writes back — the second clobbers the first and one actor is silently dropped. **Fix:** use Moneta atomic primitives / store-level lock where available, or document that Moneta is unsafe for concurrent writes.

### 15. Failover dual-write is non-atomic with no reconciliation
**File:** `lib/flipper/adapters/failover.rb:54-82`

With `dual_write: true`, primary and secondary writes are sequential and unguarded. If the secondary raises, the primary is already mutated and the exception propagates — the stores diverge permanently, and a flaky secondary breaks writes even while the primary is healthy. **Fix:** rescue/instrument the secondary write without failing the primary; provide a reconciliation path.

### 16. HTTP adapter interpolates feature/gate keys into URLs without escaping
**Files:** `lib/flipper/adapters/http.rb`, `lib/flipper/adapters/http/client.rb`

Keys are interpolated raw into paths/queries (`"/features/#{feature.key}/#{gate.key}"`, `"/features?keys=#{csv_keys}"`). A key containing `/`, `?`, `&`, `#`, a comma, or spaces produces a malformed request or injects/overrides query parameters. Keys are normally developer-controlled, hence Low. **Fix:** `URI.encode_www_form_component` each key. (Related: `uri_for_path` produces a spurious leading `&` when the base URL has no query string.)

### 17. `RedisCache` uses `Marshal.load` on cached blobs
**File:** `lib/flipper/adapters/redis_cache.rb:23,35,42`

Cache values are serialized with `Marshal.dump`/`Marshal.load`. Data is written by Flipper itself, so this is only exploitable if an attacker can write to the cache Redis — but caches are often treated as disposable/less-secured than the primary store, and `Marshal.load` is a classic RCE gadget sink. **Fix:** use a safe serializer (JSON / `Flipper::Typecast`) for cache blobs, or document that the cache store must be as trusted as the primary.

### 18. CRC32 modulo bias in percentage-of-actors bucketing
**File:** `lib/flipper/gates/percentage_of_actors.rb:33` (and `expressions/percentage_of_actors.rb`)

`Zlib.crc32(id) % (100 * SCALING_FACTOR)` is not uniform: `2**32` isn't a multiple of `100_000`, so residues `0..67_295` occur once more often than the rest. Since the "enabled" region is the low residues, buckets below 67,296 are over-represented by ≈0.0023%. Boundary conditions (0%/100%) and monotonicity are correct. Tiny fairness deviation. **Fix:** map crc32 to `[0,1)` via a full-range divisor, or use a modulus that divides the hash range.

### 19. `Poller#stop` uses `Thread#kill`
**File:** `lib/flipper/poller.rb:55-60`

`Thread#kill` asynchronously terminates the poller wherever it is (mid-`import`), can leave partially-imported state, and doesn't nil out `@thread`. The `poll-shutdown` header path runs on the poller thread and calls `stop` → self-kill mid-`sync`. **Fix:** cooperative shutdown via the existing `@shutdown_requested` AtomicBoolean checked in the run loop, then `join`; clear `@thread = nil`.

### 20. `Flipper.configuration` / `groups_registry` lazy init is racy
**File:** `lib/flipper.rb:29,182`

Module-level `@configuration ||= Configuration.new` is a non-atomic check-then-set. Two threads first touching Flipper concurrently (parallel boot/autoload) can each build a `Configuration`; the losing thread's `Flipper.configure` block results are discarded. Boot is usually single-threaded, hence Low. **Fix:** eagerly initialize at load, or memoize behind a mutex.

### 21. CLI auto-opens a server-controlled URL without confirmation
**File:** `lib/flipper/cli.rb:102-106`

`flipper cloud migrate` opens whatever `url` the `/migrate` API returns via `system("open", result.url)` with no prompt. The endpoint is overridable via `FLIPPER_CLOUD_URL`; a malicious/MITM'd endpoint yields a click-free open of an attacker-chosen URI in the developer's environment. (The array form of `system` means no shell injection.) **Fix:** validate the URL is `https://` on an allow-listed host, or just print it.

### 22. Cleartext token transmission if Cloud URL is `http://`
**File:** `lib/flipper/adapters/http/client.rb:96-99`

SSL is only enabled when `uri.scheme == "https"`. Since `url` is operator-configurable, an `http://` value sends the `flipper-cloud-token` header in cleartext with no warning. **Fix:** warn or refuse when a non-loopback Cloud URL is non-HTTPS while a token/secret is present.

### 23. Import endpoints: unbounded input and unguarded param access
**Files:** `lib/flipper/ui/actions/import.rb:12`; `lib/flipper/api/v1/actions/import.rb:16`

Both read the entire body/upload into memory before parsing (a low-grade DoS on an unauthenticated mount), and the UI path assumes `params['file']` is an upload hash — a missing/plain-string `file` raises `NoMethodError` → 500. Deserialization itself is safe (`Typecast.from_json` → plain `JSON.parse`, no object instantiation). **Fix:** guard `params['file']` presence and cap body/upload size before reading.

---

## Informational

- **24. Multi-actor percentage-of-actors semantics** (`gates/percentage_of_actors.rb:33`): with multiple actors, the gate hashes the sorted concatenation of *all* actor ids as one composite key rather than asking "is any actor in the bucket?". So `enabled?(a, b)` can be true while `enabled?(a)` and `enabled?(b)` are both false — unlike the actor/group gates which use `any?`. Long-standing behavior; worth documenting.
- **25. Minor robustness items:**
  - `Typecast.to_set` (`typecast.rb:65-74`) raises `NoMethodError` on a non-nil scalar (`value.empty?` on an Integer) instead of a clear error — only reachable with malformed adapter data.
  - `FeatureEnabled` cycle-cleanup (`expressions/feature_enabled.rb:20-30`) unconditionally deletes `feature_name` in `ensure` even on the cycle-break path where this frame didn't add it. Traced cyclic graphs still terminate correctly, but the asymmetric bookkeeping is fragile.
  - Gzip response decompression (`serializers/gzip.rb`) has no decompressed-size cap (decompression-bomb pattern) — only reachable from a hostile/MITM'd Cloud endpoint since inbound webhook/import bodies aren't gzip-decompressed.
  - Webhook failure reflects the raw exception class/message in `flipper-cloud-response-error-*` response headers (`cloud/middleware.rb:44-49`) — only after successful signature verification, so disclosure risk is minimal.
  - Per-instance `at_exit { stop }` handlers (`poller.rb:44`, `cloud/telemetry.rb:59`) accumulate and are never removed; unbounded in fork-heavy servers and inherited handlers close over stale objects.
  - **No built-in auth on UI/API** (`ui/middleware.rb`, `api/middleware.rb`): by design, but the root cause that makes findings 1, 3, and 23 reachable when the mount is misconfigured.

---

## Verified as Correct (checked, not bugs)

- **No SQL injection** in ActiveRecord/Sequel adapters — all queries use parameterized hash conditions and Arel with adapter-controlled table names.
- **Webhook HMAC comparison is timing-safe** — SHA256 digest + constant-time XOR compare in `MessageVerifier#secure_compare`; the signed message authenticates the timestamp.
- **No insecure deserialization** — cloud/import responses use plain `JSON.parse` with no object instantiation; the only `eval` is on trusted compiled template source.
- **HTTP client SSL is correct** for HTTPS URLs (`use_ssl` + `VERIFY_PEER`).
- **Mongo/Redis writes are atomic** (`$addToSet`/`$pull`, `hset`/`hdel`).
- **Path traversal** in `ui/actions/file.rb` is handled by `Rack::Files`; no open-redirect with user-controlled targets.
- **API responses are JSON-only** (no HTML rendering / reflected XSS); reflected `params["error"]` in UI views is HTML-escaped via `<%= %>`.
- Boundary conditions for both percentage gates (0% never, 100% always) and monotonicity are correct; `Registry` locking, `Actor#eql?/hash`, and per-thread cycle/sync-mode tracking are sound.
