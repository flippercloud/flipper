# Adapters

I plan on supporting the adapters in the flipper repo. Other adapters are welcome, so please let me know if you create one.

## Officially Supported

* [memory adapter](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/memory.rb) – great for tests
* [PStore adapter](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/pstore.rb) – great for when a local file is enough
* [Mongo adapter](https://github.com/jnunemaker/flipper/blob/master/docs/mongo)
* [Redis adapter](https://github.com/jnunemaker/flipper/blob/master/docs/redis)
* [ActiveRecord adapter](https://github.com/jnunemaker/flipper/blob/master/docs/active_record) - Rails 3, 4, and 5.
* [Sequel adapter](https://github.com/jnunemaker/flipper/blob/master/docs/sequel)
* [Cassanity adapter](https://github.com/jnunemaker/flipper-cassanity)

## Community Supported

* [Active Record 4 adapter](https://github.com/bgentry/flipper-activerecord)
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

If you would like to make your own adapter, there are shared adapter specs (RSpec) and tests (MiniTest) that you can use to verify that you have everything working correctly.

### RSpec
For example, here is what the in-memory adapter spec looks like:

`spec/flipper/adapters/memory_spec.rb`

```ruby
require 'helper'
require 'flipper/adapters/memory'

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
require 'flipper/adapters/memory'

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
