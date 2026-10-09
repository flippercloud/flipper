# Local Cloud memory QA

Follow-up: [production-shaped Rails/Puma/PostgreSQL run](cloud-memory-production-qa.md)
with telemetry and fault/recovery testing.

Run from this checkout:

```sh
bundle exec ruby script/cloud_memory_qa
```

The harness creates a loopback HTTPS API fixture and temporary SQLite databases.
It uses a temporary trusted certificate, dummy credentials, and disables Cloud
telemetry in the consumers. It does not use a Cloud account or existing app data.
The fixture uses this checkout's `Flipper::Api`, **not the Flipper Cloud Rails app**.
No WebMock or clock stubs are involved.

Each mode starts two independent Ruby consumers using the default Cloud setup
and a shared Active Record database. Tests cover:

- Cloud changes reaching both processes through real polling intervals.
- Signed webhook delivery through the actual Rack middleware in one consumer,
  with the other refreshing from persistence after the regular interval.
- Three batches of 160,000 evaluations per consumer, using eight threads.
  Every evaluation is checked, and each batch must perform zero database queries.
- SQL thread tracking: database operations must occur in a consumer command or
  evaluation thread, never a polling background thread.
- Application writes reaching the HTTP API and the second consumer.
- Old HTTP poll responses held across a foreground write, then released; they
  must not undo that write in the writing process.
- API outage, retained flags, recovery, and webhook failure followed by retry.
- A replacement consumer hydrating its initial state from persistent storage.

Successful runs print one JSON report per mode with timing, SQL counts, allocated
objects, post-GC live objects, RSS, and thread counts. A failed assertion exits
nonzero. Processes, server, and temporary data are cleaned up on normal exit or
test failure. The run takes roughly two minutes.

## Initial result

Local run on Ruby 3.4.2, Active Record 8.1.3.1, SQLite 3.47.0:

- Both modes passed, including restart with the API unavailable.
- 1,920,000 verified evaluations total; zero SQL in all measured batches.
- No background-thread SQL detected.
- Post-GC live objects changed by at most three per worker across the three
  batches. RSS ranged from 69.8 to 71.7 MiB; this short sample is not leak proof.
- All 281 examples in the focused Cloud, polling, synchronization, Memory,
  DualWrite, configuration, and adapter-builder suites passed.

## Evidence boundaries

This is a short correctness and resource-sampling test, not a leak certification
or a comparison with a released baseline. Timings include harness overhead and
explicit GC; they are not request-latency percentiles.

## Full Cloud soak

The harness also accepts an isolated, running Cloud Rails app:

```sh
LOCAL_CLOUD_QA_URL=https://localhost:35443/adapter \
LOCAL_CLOUD_QA_SECONDS=300 \
SSL_CERT_FILE=/path/to/qa/certificate.pem \
bundle exec ruby script/cloud_memory_qa
```

This mode requires a disposable Cloud environment with a writable token whose
value is `local-qa-only`. It deliberately only accepts HTTPS on `localhost`.
The local certificate's private key must be named `key.pem` in the same directory;
the consumers use it for their loopback HTTPS webhook listeners. Never use real
customer credentials or a production environment for this harness.

Duration is per mode, with the current phase allowed to finish. Each mode runs
two processes with eight concurrent evaluation threads each. Thirty-second load
phases cross actual refresh intervals, alternate expected flag values, and are
interspersed with application writes and cross-process convergence checks. The
harness checks SQL bounds, pool waiting, correctness, and background SQL, and
prints periodic memory/connection/thread measurements. A new consumer is started
at the end to check restart convergence.

For the initial full-app run, Cloud commit `08aaf56c5` ran on Ruby 3.3.5/Puma 6.6
against dedicated PostgreSQL 14 and MySQL 9 instances under a temporary directory.
The client used this branch (`e5841c5e`) on Ruby 3.4.2 with shared SQLite storage.
Cloud used its existing pinned Flipper dependency, not the client's branch.
The normal Cloud database configuration was replaced only in the test process;
the Cloud checkout and existing databases were untouched.

The full Rails routes, token authorization, Cloud adapter models, PostgreSQL
writes, and audit creation were exercised. An invalid token returned 404. Signed
webhooks were delivered over verified HTTPS to one consumer, which fetched Cloud
through the real adapter endpoint; the other consumer refreshed from persistence.

Safety settings: Rails test environment, test job queue, in-memory Rails cache,
disabled client telemetry, and WebMock blocking non-loopback outbound HTTP in
the Cloud server. Actual local HTTP was not stubbed. Webhook delivery was driven
by the harness, not by Cloud's queued delivery service.

### Full-app results

| Mode | Duration | Verified evaluations | SQL during read load | Final worker RSS |
| --- | ---: | ---: | ---: | ---: |
| Polling | 324 seconds | 88,000,000 | 0 | 71.8–72.1 MiB |
| Webhook | 331 seconds | 73,600,000 | 48 | 74.0–76.1 MiB |

Both modes passed all assertions, including application writes, convergence, and
restart. The webhook queries were six per thirty-second load phase across two
workers: consistent with one refresh per worker every ten seconds, not per read.
Those counts exclude setup, mutations, convergence checks, and restart queries.

There was no detected background SQL or connection-pool waiting. Each worker
settled at one idle connection. Post-GC live-object counts and thread counts
plateaued after warm-up; sampled RSS also stabilized. This is encouraging, not
proof against a slow leak. The original fault-injection matrix passed again,
and all 281 focused specs passed with seed 13146.

Remaining validation includes production edge caches, queued webhook delivery,
telemetry-enabled load, PostgreSQL/MySQL **consumer** adapters, Puma preload/fork,
database failures, simultaneous writers, and an overnight soak. These runs do
not certify those configurations or rule out slow leaks.
