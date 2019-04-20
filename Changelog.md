## 0.16.2

### Additions/Changes

* Bump rollout redis dependency to < 5 (https://github.com/jnunemaker/flipper/pull/403)
* Bump redis dependency to < 5 (https://github.com/jnunemaker/flipper/pull/401)
* Bump sequel dependency to < 6 (https://github.com/jnunemaker/flipper/pull/399 and https://github.com/jnunemaker/flipper/commit/edc767e69b4ce8daead9801f38e0e8bf6b238765)

## 0.16.1

### Additions/Changes

* Add actors API endpoint (https://github.com/jnunemaker/flipper/pull/372).
* Fix rack body proxy require for those using flipper without rack  (https://github.com/jnunemaker/flipper/pull/376).
* Unescapes feature_name in FeatureNameFromRoute (https://github.com/jnunemaker/flipper/pull/377).
* Replace delete_all with destroy_all in ActiveRecord adapter (https://github.com/jnunemaker/flipper/pull/395)
* Target correct bootstrap breakpoints in flipper UI (https://github.com/jnunemaker/flipper/pull/396)

## 0.16.0

### Bug Fixes

* Support slashes in feature names (https://github.com/jnunemaker/flipper/pull/362).

### Additions/Changes

* Re-order gates for improved performance in some cases (https://github.com/jnunemaker/flipper/pull/370).
* Add Feature#exist?, DSL#exist? and Flipper#exist? (https://github.com/jnunemaker/flipper/pull/371).

## 0.15.0

* Move Flipper::UI configuration options to Flipper::UI::Configuration (https://github.com/jnunemaker/flipper/pull/345).
* Bug fix in adapter synchronizing and switched DSL#import to use Synchronizer (https://github.com/jnunemaker/flipper/pull/347).
* Fix AR adapter table name prefix/suffix bug (https://github.com/jnunemaker/flipper/pull/350).
* Allow feature names to end with "features" in UI (https://github.com/jnunemaker/flipper/pull/353).

## 0.14.0

* Changed sync_interval to be seconds instead of milliseconds.

## 0.13.0

### Additions/Changes

* Update PStore adapter to allow setting thread_safe option (https://github.com/jnunemaker/flipper/pull/334).
* Update Flipper::UI to Bootstrap 4 (https://github.com/jnunemaker/flipper/pull/336).
* Add Flipper::UI configuration to add a banner with customizeable text and background color (https://github.com/jnunemaker/flipper/pull/337).
* Add sync adapter (https://github.com/jnunemaker/flipper/pull/341).
* Make cloud use sync adapter (https://github.com/jnunemaker/flipper/pull/342). This makes local flipper operations resilient to cloud failures.

## 0.12.2

### Additions/Changes

* Improvements/fixes/examples for rollout adapter (https://github.com/jnunemaker/flipper/pull/332).

## 0.12.1

### Additions/Changes

* Added rollout adapter documentation (https://github.com/jnunemaker/flipper/pull/328).  

### Bug Fixes

* Fixed ActiveRecord and Sequel adapters to include disabled features for `get_all` (https://github.com/jnunemaker/flipper/pull/327).

## 0.12

### Additions/Changes

* Added Flipper.instance= writer method for explicitly setting the default instance (https://github.com/jnunemaker/flipper/pull/309).
* Added Flipper::UI configuration instance for changing text and things (https://github.com/jnunemaker/flipper/pull/306).
* Delegate memoize= and memoizing? for Flipper and Flipper::DSL (https://github.com/jnunemaker/flipper/pull/310).
* Fixed error when enabling the same group or actor more than once (https://github.com/jnunemaker/flipper/pull/313).
* Fixed redis cache adapter key (and thus cache misses) (https://github.com/jnunemaker/flipper/pull/325).
* Added Rollout adapter to make it easy to import rollout data into Flipper (https://github.com/jnunemaker/flipper/pull/319).
* Relaxed redis gem dependency constraint to allow redis-rb 4 (https://github.com/jnunemaker/flipper/pull/317).
* Added configuration option for Flipper::UI to disable feature removal (https://github.com/jnunemaker/flipper/pull/322).

## 0.11

### Backwards Compatibility Breaks

* Set flipper from env for API and UI (https://github.com/jnunemaker/flipper/pull/223 and https://github.com/jnunemaker/flipper/pull/229). It is documented, but now the memoizing middleware requires that the SetupEnv middleware is used first, unless you are configuring a Flipper default instance.
* Drop support for Ruby 2.0 as it is end of lined (https://github.com/jnunemaker/flipper/commit/c2c81ed89938155ce91acb5173ac38580f630e3d).
* Allow unregistered groups (https://github.com/jnunemaker/flipper/pull/244). Only break in compatibility is that previously unregistered groups could not be enabled and now they can be.
* Removed support for metriks (https://github.com/jnunemaker/flipper/pull/291).

### Additions/Changes

* Use primary keys with sequel adapter (https://github.com/jnunemaker/flipper/pull/210). Should be backwards compatible, but if you want it to work this way you will need to migrate your database to the new schema.
* Add redis cache adapter (https://github.com/jnunemaker/flipper/pull/211).
* Finish API and HTTP adapter that speaks to API.
* Add flipper cloud adapter (https://github.com/jnunemaker/flipper/pull/249). Nothing to see here yet, but good stuff soon. ;)
* Add importing (https://github.com/jnunemaker/flipper/pull/251).
* Added Adapter#get_all to allow for more efficient preload_all (https://github.com/jnunemaker/flipper/pull/255).
* Added :unless option to Flipper::Middleware::Memoizer to allow skipping memoization and preloading for certain requests.
* Made it possible to instrument Flipper::Cloud (https://github.com/jnunemaker/flipper/commit/4b10e4d807772202f63881f5e2c00d11ac58481f).
* Made it possible to wrap Http adapter when using Flipper::Cloud (https://github.com/jnunemaker/flipper/commit/4b10e4d807772202f63881f5e2c00d11ac58481f).
* Instrument get_multi in instrumented adapter (https://github.com/jnunemaker/flipper/commit/951d25c5ce07d3b56b0b2337adf5f6bcbe4050e7).
* Allow instrumenting Flipper::Cloud http adapter (https://github.com/jnunemaker/flipper/pull/253).
* Add DSL#preload_all and Adapter#get_all to allow for making even more efficient loading of features (https://github.com/jnunemaker/flipper/pull/255).
* Allow setting debug output of http adapter (https://github.com/jnunemaker/flipper/pull/256 and https://github.com/jnunemaker/flipper/pull/258).
* Allow setting env key for middleware (https://github.com/jnunemaker/flipper/pull/259).
* Added ActiveSupport cache store adapter for use with Rails.cache (https://github.com/jnunemaker/flipper/pull/265 and https://github.com/jnunemaker/flipper/pull/297).
* Added support for up to 3 decimal places in percentage based rollouts (https://github.com/jnunemaker/flipper/pull/274).
* Removed Flipper::GroupNotRegistered error as it is now unused (https://github.com/jnunemaker/flipper/pull/270).
* Added get_all to all adapters (https://github.com/jnunemaker/flipper/pull/298).
* Added support for Rails 5.1 (https://github.com/jnunemaker/flipper/pull/299).
* Added Flipper default instance generation (https://github.com/jnunemaker/flipper/pull/279).

## 0.10.2

* Add Adapter#get_multi to allow for efficient loading of more than one feature at a time (https://github.com/jnunemaker/flipper/pull/198)
* Add DSL#preload for efficiently loading several features at once using get_mutli (https://github.com/jnunemaker/flipper/pull/198)
* Add :preload and :preload_all options to memoizer as a way of efficiently loading several features for a request in one network call instead of N where N is the number of features checked (https://github.com/jnunemaker/flipper/pull/198)
* Strip whitespace out of feature/actor/group values posted by UI (https://github.com/jnunemaker/flipper/pull/205)
* Fix bug with dalli adapter where deleting a feature using the UI or API was not clearing the cache in the dalli adapter which meant the feature would continue to use whatever cached enabled state was present until the TTL was hit (1cd96f6)
* Change cache keys for dalli adapter. Backwards compatible in that it will just repopulate new keys on first check with this version, but old keys are not expired, so if you used the default ttl of 0, you'll have to expire them on your own. The primary reason for the change was safer namespacing of the cache keys to avoid collisions.

## 0.10.1

* Add docker compose support for contributing
* Add sequel adapter
* Show confirmation dialog when deleting a feature in flipper-ui

## 0.10.0

* Added feature check context (https://github.com/jnunemaker/flipper/pull/158)
* Do not use mass assignment for active record adapter (https://github.com/jnunemaker/flipper/pull/171)
* Several documentation improvements
* Make Flipper::UI.app.inspect return a String (https://github.com/jnunemaker/flipper/pull/176)
* changes boolean gate route to api/v1/features/boolean (https://github.com/jnunemaker/flipper/pull/175)
* add api v1 percentage_of_actors endpoint (https://github.com/jnunemaker/flipper/pull/179)
* add api v1 percentage_of_time endpoint (https://github.com/jnunemaker/flipper/pull/180)
* add api v1 actors gate endpoint  (https://github.com/jnunemaker/flipper/pull/181)
* wait for activesupport to tell us when active record is loaded for active record adapter (https://github.com/jnunemaker/flipper/pull/192)

## 0.9.2

* GET /api/v1/features
* POST /api/v1/features - add feature endpoint
* rack-protection 2.0.0 support
* pretty rake output

## 0.9.1

* bump flipper-active_record to officially support rails 5

## 0.9.0

* Moves SharedAdapterTests module to Flipper::Test::SharedAdapterTests to avoid clobbering anything top level in apps that use Flipper
* Memoizable, Instrumented and OperationLogger now delegate any missing methods to the original adapter. This was lost with the removal of the official decorator in 0.8, but is actually useful functionality for these "wrapping" adapters.
* Instrumenting adapters is now off by default. Use Flipper::Adapters::Instrumented.new(adapter) to instrument adapters and maintain the old functionality.
* Added dalli cache adapter (https://github.com/jnunemaker/flipper/pull/132)

## 0.8

* removed Flipper::Decorator and Flipper::Adapters::Decorator in favor of just calling methods on wrapped adapter
* fix bug where certain versions of AR left off quotes for key column which caused issues with MySQL https://github.com/jnunemaker/flipper/issues/120
* fix bug where AR would store multiple gate values for percentage gates for each enable/disable and then nondeterministically pick one on read (https://github.com/jnunemaker/flipper/pull/122 and https://github.com/jnunemaker/flipper/pull/124)
* added readonly adapter (https://github.com/jnunemaker/flipper/pull/111)
* flipper groups now match for truthy values rather than explicitly only true (https://github.com/jnunemaker/flipper/issues/110)
* removed gate operation instrumentation (https://github.com/jnunemaker/flipper/commit/32f14ed1fb25c64961b23c6be3dc6773143a06c8); I don't think it was useful and never found myself instrumenting it in reality
* initial implementation of flipper api - very limited functionality right now (get/delete feature, boolean gate for feature) but more is on the way
* made it easy to remove a feature (https://github.com/jnunemaker/flipper/pull/126)
* add minitest shared tests for adapters that work the same as the shared specs for rspec (https://github.com/jnunemaker/flipper/pull/127)

## 0.7.5

* support for rails 5 beta/ rack 2 alpha
* fix uninitialized constant in rails generators
* fix adapter test for clear to ensure that feature is not deleted, only gates

## 0.7.4

* Add missing migration file to gemspec for flipper-active_record

## 0.7.3

* Add Flipper ActiveRecord adapter

## 0.7.2

* Add Flipper::UI.application_breadcrumb_href for setting breadcrumb back to original app from Flipper UI

## 0.7.1

* Fix bug where features with names that match static file routes were incorrectly routing to the file action (https://github.com/jnunemaker/flipper/issues/80)

## 0.7

* Added Flipper.groups and Flipper.group_names
* Changed percentage_of_random to percentage_of_time
* Added enable/disable convenience methods for all gates (ie: enable_group, enable_actor, enable_percentage_of_actors, enable_percentage_of_time)
* Added value convenience methods (ie: boolean_value, groups_value, actors_value, etc.)
* Added Feature#gate_values for getting typecast adapter gate values
* Added Feature#enabled_gates and #disabled_gates for getting the gates that are enabled/disabled for the feature
* Remove Feature#description
* Added Flipper::Adapters::PStore
* Moved memoizable decorator to instance variable storage from class level thread local stuff. Now not thread safe, but we can make a thread safe version later.

UI

* Totally new. Works like a charm.

Mongo

* Updated to latest driver (~> 2.0)

## 0.6.3

* Minor bug fixes

## 0.6.2

* Added Flipper.group_exists?

## 0.6.1

* Added statsd support for instrumentation.

## 0.4.0

* No longer use #id for detecting actors. You must now define #flipper_id on
  anything that you would like to behave as an actor.
* Strings are now used instead of Integers for Actor identifiers. More flexible
  and the only reason I used Integers was to do modulo for percentage of actors.
  Since percentage of actors now uses hashing, integer is no longer needed.
* Easy integration of instrumentation with AS::Notifications or anything similar.
* A bunch of stuff around inspecting and getting names/descriptions out of
  things to more easily figure out what is going on.
* Percentage of actors hash is now also seeded with feature name so the same
  actors don't get all features instantly.
