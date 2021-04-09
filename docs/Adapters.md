# Adapters

I plan on supporting the adapters in the flipper repo. Other adapters are welcome, so please let me know if you create one.

## Officially Supported

* [ActiveRecord adapter](https://github.com/jnunemaker/flipper/blob/master/docs/active_record) - Rails 3, 4, 5, and 6.
* [ActiveSupportCacheStore adapter](https://github.com/jnunemaker/flipper/blob/master/docs/active_support_cache_store) - ActiveSupport::Cache::Store
* [Cassanity adapter](https://github.com/jnunemaker/flipper-cassanity)
* [Http adapter](https://github.com/jnunemaker/flipper/blob/master/docs/http)
* [memory adapter](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/memory.rb) – great for tests
* [Moneta adapter](https://github.com/jnunemaker/flipper/blob/master/docs/moneta)
* [Mongo adapter](https://github.com/jnunemaker/flipper/blob/master/docs/mongo)
* [PStore adapter](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/pstore.rb) – great for when a local file is enough
* [read-only adapter](https://github.com/jnunemaker/flipper/blob/master/docs/read-only)
* [Redis adapter](https://github.com/jnunemaker/flipper/blob/master/docs/redis)
* [Rollout adapter](rollout/README.md)
* [Sequel adapter](https://github.com/jnunemaker/flipper/blob/master/docs/sequel)

## Community Supported

* [Active Record 3 adapter](https://github.com/blueboxjesse/flipper-activerecord)
* [Consul adapter](https://github.com/gdavison/flipper-consul)

## Roll Your Own

The basic API for an adapter is this:

* `features` - Get the set of known features.
* `add(feature)` - Add a feature to the set of known features.
* `remove(feature)` - Remove a feature from the set of known features.
* `clear(feature)` - Clear all gate values for a feature.
* `get(feature)` - Get all gate values for a feature.
* `enable(feature, gate, thing)` - Enable a gate for a thing.
* `disable(feature, gate, thing)` - Disable a gate for a thing.
* `get_multi(features)` - Get all gate values for several features at once. Implementation is optional. If none provided, default implementation performs N+1 `get` calls where N is the number of elements in the features parameter.
* `get_all` - Get all gate values for all features at once. Implementation is optional. If none provided, default implementation performs two calls, one to `features` to get the names of all features and one to `get_multi` with the feature names from the first call.

If you would like to make your own adapter, there are shared adapter specs (RSpec) and tests (MiniTest) that you can use to verify that you have everything working correctly.

### RSpec
For example, here is what the in-memory adapter spec looks like:

`spec/flipper/adapters/memory_spec.rb`

```ruby
require 'helper'

# The shared specs are included with the flipper gem so you can use them in
# separate adapter specific gems.
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Memory do

  # an instance of the new adapter you are trying to create
  subject { described_class.new }

  # include the shared specs that the subject must pass
  it_should_behave_like 'a flipper adapter'
end
```

### MiniTest

Here is what an in-memory adapter MiniTest looks like:

`test/adapters/memory_test.rb`

```ruby
require 'test_helper'

class MemoryTest < MiniTest::Test
  prepend SharedAdapterTests

  def setup
    # Any code here will run before each test
    @adapter = Flipper::Adapters::Memory.new
  end

  def teardown
    # Any code here will run after each test
  end
end
```
1. Create a file under `test/adapters` that inherits from MiniTest::Test.

2. `prepend SharedAdapterTests`.

3. Initialize an instance variable `@adapter` referencing an instance of the adapter.

4. Add any code to run before each test in a `setup` method and any code to run after each test in a `teardown` method.

A good place to start when creating your own adapter is to copy one of the adapters mentioned above and replace the client specific code with whatever client you are attempting to adapt.

I would also recommend setting `fail_fast = true` in your RSpec configuration as that will just give you one failure at a time to work through. It is also handy to have the shared adapter spec file open.

## Swapping Adapters

If you find yourself using one adapter and would like to swap to another, you can do that! Flipper adapters support importing another adapter's data. This will wipe the adapter you are wanting to swap to, if it isn't already clean, so please be careful.

```ruby
# Say you are using redis...
redis_adapter = Flipper::Adapters::Redis.new(Redis.new)
redis_flipper = Flipper.new(redis_adapter)

# And redis has some stuff enabled...
redis_flipper.enable(:search)
redis_flipper.enable_percentage_of_time(:verbose_logging, 5)
redis_flipper.enable_percentage_of_actors(:new_feature, 5)
redis_flipper.enable_actor(:issues, Flipper::Actor.new('1'))
redis_flipper.enable_actor(:issues, Flipper::Actor.new('2'))
redis_flipper.enable_group(:request_tracing, :staff)

# And you would like to switch to active record...
ar_adapter = Flipper::Adapters::ActiveRecord.new
ar_flipper = Flipper.new(ar_adapter)

# NOTE: This wipes active record clean and copies features/gates from redis into active record.
ar_flipper.import(redis_flipper)

# active record is now identical to redis.
ar_flipper.features.each do |feature|
  pp feature: feature.key, values: feature.gate_values
end
```
