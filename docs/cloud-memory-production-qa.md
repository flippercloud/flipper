# Production-shaped local QA — 2026-09-07

## Partial-failure regression tests — 2026-09-09

Initial investigation of client `0e68ee45`: six deterministic scenarios run against Memory persistence
and again against the actual Active Record adapter backed by isolated in-memory
SQLite. Each run passed four scenarios and failed two. These are composition
tests using the real Poller with scheduled background execution disabled,
controlled monotonic time, and injected adapter exceptions; they do not boot the
full Cloud server or access any external service.

Passing:

- A two-feature refresh interrupted before the second persistent enable commits
  converges on the next interval using the same buffered snapshot.
- The same refresh interrupted after the second enable commits, but before its
  Memory write, also converges on retry.
- A refresh interrupted during feature removal retries and converges.
- Following a failed explicit write, a newly successful Cloud poll restores
  convergence.

Failing, with Cloud unavailable during recovery:

- An unrelated explicit write rejected at Cloud consumes an existing pending
  snapshot. Recovering persistence does not apply that snapshot.
- An unrelated explicit write accepted at Cloud but rejected at persistence
  likewise prevents retry of the pending snapshot's unrelated changes.

Both failures trace to `IntervalSynchronizer::State#synchronize_write` consuming
pending polls before yielding, including when the write raises. This is a lost
retry until another Cloud poll succeeds, not a read-availability failure.
Unconditionally replaying an older snapshot is not a safe fix when a write might
already have succeeded remotely. The pre-write generation fence also protects
ordering, so moving it without concurrency coverage is unsafe.

Decision: accept the existing write-generation fence, without per-feature
tracking. A partially applied poll remains retryable until an explicit write
supersedes it. After that write (successful or failed), freshness requires a new
successful Cloud poll followed by successful caller-thread reconciliation.
Reads remain available, but may remain stale throughout the overlapping outage.
Partial synchronization is not atomic across features.

The six specs in `spec/flipper/cloud/partial_failure_spec.rb` now assert this
contract: stale reads while Cloud is unavailable, then convergence after a fresh
poll. All six pass with Memory and again with Active Record/SQLite. No runtime
implementation changes or production deployments were made for this decision.
The isolated Active Record runner is
`/private/tmp/flipper-cloud-soak.FnEbjg/partial-active-record.rb`.

## Targeted outage rerun — 2026-09-09

Passed against client commit `0e68ee45`, with full local Cloud at `11deed4fa`,
two preloaded Puma workers, five threads each, and disposable PostgreSQL/MySQL.
Both applications and the request generator blocked non-localhost outbound HTTP.
This was a targeted regression exercise, not a repeat of the full soak below.

- Stopped the consumer PostgreSQL cluster. An explicit write returned HTTP 500.
- Published a Cloud update after that failed write, then confirmed both workers
  had buffered the new snapshot and had failed their foreground reconciliation.
- Paused the local Cloud process. During 25 seconds of eight-thread load,
  all 13,104 read requests served the expected stale value, with 100 consistent
  evaluations per request. No read failures occurred.
- Each worker recorded three reconciliation failures. Inter-attempt gaps were
  10.107–10.118 seconds, respecting the ten-second polling interval.
- Restarted PostgreSQL while Cloud remained paused. Both workers became fresh in
  3.972 seconds, with their buffered poll generation unchanged at 2. This proves
  recovery retried the existing snapshot without another successful Cloud fetch.
- An additional 2,631 requests served the fresh value with no errors.
- No background SQL was detected. Sampled connection pools had zero waiting
  clients. RSS after load/recovery was approximately 104 MiB per worker.

The explicit failing write preceded the snapshot under test: explicit writes
supersede older poll generations under the existing ordering rules. This run does
not claim atomic rollback for partially applied multi-feature snapshots or verify
telemetry delivery. The earlier full-soak observations remain historical.

The temporary runner and numeric results are
`/private/tmp/flipper-cloud-soak.FnEbjg/outage-rerun.rb` and
`/private/tmp/flipper-cloud-soak.FnEbjg/outage-rerun-results.json`.

## Outcome

Both polling and webhook modes completed the request, fork/restart, concurrency,
and recovery exercises. A read-availability difference needs a rollout decision:

**Polling can fail a read when a newer Cloud snapshot needs to be persisted but
the local database is unavailable. Webhook-mode reads retain the cached state.**

No Flipper implementation changes were made during this exercise.

## Setup

- Client: branch `cloud-memory-reads`, commit `e5841c5e`.
- Rails 8.1.3.1, Ruby 3.4.2, Puma 8.0.2; two preloaded workers, five threads each.
- Real Rails controller requests, executor lifecycle, and Flipper request memoization.
- Flipper initialized before fork, including telemetry and (in polling mode) the poller.
- Only the normal Active Record disconnect hook before fork; no custom Flipper resets.
- A separate, disposable PostgreSQL 14 cluster for the consumer, pool size five.
- Full local Cloud application, isolated PostgreSQL/MySQL databases, verified HTTPS.
- Telemetry enabled at a ten-second interval; local Cloud verified and accepted payloads.
- Eight concurrent request generators; 100 checked flag evaluations per request.
- No production access. Non-loopback outbound HTTP blocked in both applications.

The Cloud server used a shared Memory adapter for its own internal flags, a
synthetic subscription fixture, and a test job queue. Telemetry acceptance was
tested through the real endpoint; queued analytics processing and Cloud's queued
webhook dispatcher were not exercised. Signed webhook requests were sent by the
test harness to one randomly selected Puma worker. The other refreshed from SQL.

## Results

| Exercise | Polling | Webhooks |
| --- | --- | --- |
| Normal request load and flag changes | Correct responses | Correct responses; other worker converged in roughly 9–10 seconds |
| Eight simultaneous writes | 8/8 returned 200; converged | 8/8 returned 200; converged after webhook |
| Replace one worker | Recovered and converged | Recovered and converged |
| Restart entire preloaded cluster | Recovered and converged | Recovered and converged |
| Pause Cloud for 25 seconds | Warm reads stayed 200 | Warm reads stayed 200 |
| Stop consumer PostgreSQL, no new Cloud state | Warm reads stayed 200 | Warm reads stayed 200 |
| Change Cloud state while consumer PostgreSQL is stopped | 332 read failures; 9,800 successful cached reads in the 20-second phase | 12,365 successful cached reads; no read failures in the 20-second phase |
| Explicit write while PostgreSQL is stopped | 500 | 500; explicit webhook sync also returned 500 |
| Restore PostgreSQL | Converged in 0.60 seconds without consumer restart | Converged in 9.28 seconds after retrying webhook; no consumer restart |
| Telemetry | Accepted after correcting fixture; outage queue drained | Accepted; outage queue drained |

Across completed measured phases, including repeated polling passes while fixing
the harness setup, there were 53,288,100 verified evaluations. No successful
response returned an unexpected flag value or inconsistent within-request values.
This was not one uninterrupted soak of that volume.

Healthy steady-state p95 was approximately 9–12 ms locally; the polling
database-outage/new-snapshot phase raised p99 to approximately 117 ms. These
include loopback HTTPS and request-generator overhead, and are not a comparison
against a released baseline. Restart warm-up phases had additional latency.

No background-thread SQL was detected. Sampled pools generally had one idle
connection and zero waiting clients. Thread counts settled at 17 per polling
worker and 16 per webhook worker; warmed RSS samples were roughly 104–111 MiB.
These samples do not rule out transient pool waits or slow leaks.

## Why the read behavior differs

`Poll#synchronize` invokes `Sync::Synchronizer` with its default error-raising
behavior before returning the read adapter. When a new snapshot requires a
persistent write, an unavailable database therefore fails the triggering read.
Concurrent callers can still read the old Memory state while the shared sync lock
is busy. Failed reconciliation remains pending and is retried by later reads.

`Sync`, used for webhook refresh, constructs its synchronizer with `raise: false`.
Failed periodic refresh leaves cached reads available and the interval controls
the next attempt. Explicit writes and webhook syncs still report errors.

Before widening rollout, decide whether polling should also preserve read
availability on reconciliation failure. Any fix should keep failures observable,
avoid hot-looping retries, and retain explicit write/webhook error semantics.
This run does not establish that the outage behavior is a regression from the
released gem; the baseline was not subjected to this matrix.

## Setup issues separated from Flipper findings

1. Native `pg`/libpq crashed on macOS after fork. A minimal program using only
   `pg`, with no Rails or Flipper, reproduced the crash. The same probe passed
   with `gssencmode: disable`. That setting was applied only to the disposable
   consumer database connection. It is not a proposed Flipper change.
2. The minimal Rails app initially lacked an `ApplicationRecord` base class,
   leaving Active Record's lazy initialization incomplete; the fixture was fixed.
3. Planned Puma hot restart caused transient TLS connection timeouts. The harness
   was adjusted to retry worker discovery within its existing 45-second deadline.
4. Cloud telemetry was initially disabled by a thread-local test flag, then by
   the synthetic account's free-plan entitlement. The fixture was corrected to
   share its internal flag store and include a local subscription row without
   billing calls. Rejected submissions are not counted as successful delivery;
   acceptance was verified afterward, including both restarted polling workers.
5. The mounted webhook app emitted the existing nested-Memoizer warning under
   Rails' outer memoizer. The inner middleware detects that memoization is already
   active and passes through; ordinary controller checks were not double-wrapped.
   No middleware behavior was changed to suppress the warning.

## Artifacts and limits

The adjacent `cloud-memory-production-results.json` contains the captured phase
reports. Disposable Rails/Puma fixtures, runner, and the minimal native fork
probe were created under `/private/tmp/flipper-cloud-soak.FnEbjg`.

Remaining gates include a Linux run without the macOS-specific database setting,
production edge-cache behavior, queued webhook delivery, full telemetry ingestion,
multi-feature/large-snapshot failure cases, and a longer soak. No deployment or
canary was performed, and no existing development database was modified.
All temporary application and database services were stopped after testing.
