# Cloud snapshot synchronization

Cloud sends a full feature snapshot with an optional `flipper-sync-version`
response header. The revision and features describe the same database snapshot.
Revision zero is valid; a missing header means the source is unversioned.

Memory (with its default mutex) and Active Record can install these snapshots
atomically. They reject lower revisions, reconcile equal or higher revisions,
and publish the new revision only with the completed feature changes. Equal
revisions still reconcile local edits; identical data causes no gate writes.
Failed installation leaves the prior data and revision intact.

During Memory installation, feature-event subscribers can read the previous
complete snapshot. They must not mutate that same adapter reentrantly; doing
so raises and aborts the installation before publication.

Active Record requires the additive `flipper_sync_states` table. For an existing
installation, run `rails generate flipper:update` and `rails db:migrate`.
New installations include it in `rails generate flipper:active_record`.
The update migration preserves existing feature/gate data and is deliberately
irreversible, so rollback cannot drop a table that already existed. Retain the
additive table when rolling back the SDK.

Active Record supports PostgreSQL, MySQL, and SQLite when feature, gate, and
sync-state models share one writing connection pool. The `table_prefix` option
applies to all three tables; custom models can use `sync_state_class` alongside
`feature_class` and `gate_class`. Versioned installation must run outside an
existing database transaction. This ensures the locked revision and feature
diff cannot use different database snapshots. Installation reads and writes
use the primary connection; ordinary replica reads can still lag.

Other adapters, unsupported connection configurations, and multi-store/cache
wrappers keep the existing diff-based synchronization behavior. They do not
claim atomic rollback or stale-response protection. Transparent wrappers may
delegate the capability; Memoizable clears its cache after installation and
ReadOnly prohibits installation. An installation error never silently falls
back to non-atomic writes.

## Store ownership and resets

Use each local store for one configured Cloud environment. Token rotation for
that same environment does not reset revisions. To change environments, restore
a source to a lower counter, or otherwise reset the revision namespace:

1. Stop every sync writer and drain its in-flight work, including pollers and
   webhook workers in every process sharing the store.
2. Use a fresh store or deliberately import the desired source into the old
   store. Explicit imports are unconditional and clear its private revision
   floor. Recreate pollers when changing their source.
3. Start the writers with the new configuration.

Unversioned responses also reconcile unconditionally and clear the floor. This
preserves operation with released servers but relinquishes ordering protection.
Do not mix old SDK writers with version-aware writers and expect monotonic
installation: old writers do not participate in the boundary.

The stored revision is only an acceptance floor, not a claim that locally
editable data still exactly matches Cloud. Memory and Active Record export
unversioned local snapshots. The background poller separately retains an owned,
immutable upstream snapshot so its revision stays paired with its exact data.

The guarantee applies to participating snapshot installers, not arbitrary SQL,
ordinary local edits, or independent feature evaluations spanning a commit.
Local edits need no dirty flag: an equal authoritative snapshot reconciles them
on the next sync.

## Adapter contract

`get_all_snapshot` returns a `Flipper::Snapshot` containing features and an
optional nonnegative integer revision. An adapter must return an unversioned
snapshot unless it can guarantee that pairing.

`supports?(:atomic_snapshot_install)` advertises the optional
`apply_snapshot(snapshot, instrumenter: ...)` operation. It returns `:applied`,
`:unchanged`, or `:stale`. Unsupported adapters report false; the default
implementation raises `NotImplementedError`. Keep fetching outside storage
locks, then compare the revision, read, diff, write, and publish inside one
authoritative boundary. A nil revision reconciles unconditionally and clears
the private floor. Preserve feature-operation instrumentation when reconciling.

Complete the Cloud deployment, including all payload-changing writers, before
releasing the SDK that consumes these revisions.
