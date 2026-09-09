# Cloud memory reads: compatibility and performance

Date: 2026-09-09. Implementation: `0e68ee45005eaf87d7c30f8c29c84aa904c9da75`.
Baseline: latest published release, `v1.4.2` (`50a8207ada6c93fd4c29bcee683660b7351647a7`).
No production services were used or deployments performed.

## Recovery contract

No per-feature generation tracking was added. Interrupted automatic refreshes
retry on the normal interval and may expose a mix of older and newer features.
An intervening explicit write, even if it fails, supersedes older poll snapshots.
Freshness then requires another successful Cloud poll and local reconciliation.
The README now states this limitation.

All six partial-failure specs pass with Memory and again with isolated
Active Record/SQLite. They cover before/after-commit failures, interrupted removal,
stale reads after failed writes, and convergence after a fresh Cloud poll.

## Compatibility

Verified existing CI results for the exact implementation commit, not a new CI
run of the uncommitted documentation/spec additions:

- All 23 stable Ruby/Rails combinations passed, spanning Ruby 2.6–3.3 and
  supported Rails 5.2–8.0 combinations.
- Rack 2.0.9.4 minimum compatibility passed.
- All 23 example application combinations passed.
- The nonblocking Rails-main canary failed in the browser system test
  `TestHelpTest#test_configures_a_shared_adapter_between_tests_and_app` with a
  Ferrum timeout and subsequent missing execution context. Its 3,043 RSpec
  examples and 310 Minitest runs passed. This was not proven to be a flaky test
  or a Flipper defect; it remains an unresolved nonblocking canary failure.

Sources: [CI run](https://github.com/flippercloud/flipper/actions/runs/34367338346),
[example applications](https://github.com/flippercloud/flipper/actions/runs/34367338407).

Additional local ARM64 Linux run, including the six updated specs:

- RSpec: **3,014 examples, zero failures, two pending**. Pending examples are
  SQLite role-switching cases; MongoDB specs were excluded because this local
  container did not have MongoDB. CI above provides MongoDB coverage.
- Minitest: **310 runs, 7,411 assertions, zero failures/errors, 34 skips**.
- PostgreSQL, MariaDB, Redis and Memcached ran inside a disposable container with
  networking disabled. No host development database was accessed.
- The local run did not repeat browser system tests or every Ruby/Rails pairing.

## Benchmark method

- Linux ARM64, Ruby 3.3.12, Rails 8.1.3.1, Puma 8.0.2, pg 1.6.3, Redis gem 4.8.1.
- Same dependencies and harness for both source versions; source load path was
  switched between archived release and branch code.
- One Puma process with five threads; five concurrent persistent HTTP clients.
- Default Rails request memoization and preload-all behavior; each request checks
  100 distinct enabled flags and asserts a successful, correct response.
- 1,000 and 5,000 boolean flags; PostgreSQL with normal Flipper indexes or Redis.
- Twenty warm-up requests, then a five-second measurement; three fresh-process
  repetitions per case with alternating version order. Values below are medians
  across those repetitions, not pooled percentiles or confidence intervals.
- Cloud adapter HTTP was supplied by an in-process Flipper API fixture through
  WebMock. Polling remained enabled. This measures application/adapter costs,
  not internet latency, the production Cloud service, or edge caches.
- Cloudless runs provide a control using the same 1,000-flag workload.
- Ruby CPU and allocations are measured in the server process. RSS is sampled
  after GC, not peak memory or evidence of long-term leak freedom.

Preliminary samples were discarded before rerunning the complete comparison
with indexed PostgreSQL tables and no overlapping test-suite execution. A later
fixture correction disabled Rack compression inside WebMock's transport bridge;
otherwise simulated Cloud fetches failed while warm reads still worked. Final
runs explicitly verify a successful Cloud fetch before measurement.

## Steady-state results

| Backend / flags | Requests/sec: release → branch | p95 ms: release → branch | p99 ms: release → branch |
| --- | ---: | ---: | ---: |
| PostgreSQL / 1,000 | 121.5 → 322.6 | 52.5 → 18.9 | 71.9 → 21.9 |
| PostgreSQL / 5,000 | 36.8 → 111.1 | 168.0 → 56.6 | 196.7 → 69.1 |
| Redis / 1,000 | 39.0 → 290.4 | 178.9 → 22.7 | 222.5 → 25.7 |
| Redis / 5,000 | 7.1 → 110.4 | 911.8 → 53.7 | 1,063.5 → 64.6 |

All measured branch polling samples performed **zero persistent-adapter reads**.
The release performed approximately one adapter read per request, plus poll
reconciliation reads. PostgreSQL additionally recorded approximately one SQL
query per release request versus zero on the branch. Adapter
read counts are not Redis command counts: one adapter read can issue many commands.

| Backend / flags | Allocations/request: release → branch | Ruby CPU ms/request: release → branch | RSS MiB: release → branch |
| --- | ---: | ---: | ---: |
| PostgreSQL / 1,000 | 56,921 → 9,924 | 7.76 → 2.87 | 120.4 → 113.3 |
| PostgreSQL / 5,000 | 256,444 → 25,843 | 26.62 → 8.82 | 162.8 → 159.8 |
| Redis / 1,000 | 136,283 → 9,931 | 24.37 → 3.13 | 472.3 → 159.8 |
| Redis / 5,000 | 655,370 → 26,242 | 138.16 → 8.89 | 783.3 → 259.1 |

Cloudless throughput: PostgreSQL **120.5 → 153.7 requests/sec**; Redis
**41.89 → 41.85 requests/sec** (effectively unchanged). No material throughput regression was observed in these
controls. The release-to-branch comparison includes all intervening changes,
so improvements outside Cloud should not be attributed solely to memory reads.

## Changing-flags workload

Separate 25-second runs used 1,000 flags, toggled an additional flag every three
seconds, and required a final enabled state to reach local reads. Each version
completed two or three successful Cloud fetches during the measured window.

| Backend | Requests/sec: release → branch | p95 ms: release → branch |
| --- | ---: | ---: |
| PostgreSQL | 134.3 → 327.8 | 45.7 → 18.3 |
| Redis | 39.1 → 344.9 | 170.9 → 16.7 |

On PostgreSQL the branch performed 12 SQL statements for reconciliation during
the entire window, versus 3,468 on the release. Branch persistent-adapter read
counts remained zero on both backends. All runs reached the final requested
state; release convergence took 6.93 seconds (PostgreSQL) and 6.25 seconds
(Redis), while the branch already matched when checked. These are individual
runs at different poll phases, not evidence of a guaranteed freshness advantage.
They demonstrate actual update application under read load.

## Limits and observations

One preliminary released-version Redis/5,000-flag fixture hung on server
teardown. It was stopped and a bounded shutdown wait added. No cause was
established, and all preliminary samples were discarded. This harness is not a
lifecycle soak.

No bounded shutdown was required during the final corrected-fixture runs.

These short, preload-heavy, local ARM64 measurements support better read-path
performance, not a promise of these speedups on every application. Non-memoized
workloads, mixed actor/expression datasets, production x86 timing, long-running
memory behavior, and full production Cloud behavior remain outside this run.
Five-second samples, especially the slower Redis/5,000-flag baseline, contain
few requests; tail percentiles are directional measurements, not precise SLOs.

The final runs completed 21,167 steady-state and 21,169 changing-flags requests,
each checking 100 flag evaluations without a response/value assertion failure.

The harness, build recipe and raw logs are retained locally under
`/private/tmp/flipper-compat.hSARKY`. Numeric benchmark results are saved alongside
this report. The disposable container is stopped; its image and filesystem are
retained for reproduction. No gem implementation changes were made during this validation.
