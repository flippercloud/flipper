# Adapters - V2

V2 adapters are dramatically easier to build than V1 and support more functionality.

## Officially Supported

* [memory adapter](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/v2/memory.rb) – great for tests
* [PStore adapter](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/v2/pstore.rb) – great for when a local file is enough
* [Mongo adapter](https://github.com/jnunemaker/flipper/blob/master/docs/mongo)
* [Redis adapter](https://github.com/jnunemaker/flipper/blob/master/docs/redis)
* [ActiveRecord adapter](https://github.com/jnunemaker/flipper/blob/master/docs/active_record) - Rails 3 and 4.

## Community Supported

N/A. Too early. Let me know by filing an issue or something if you build one.

## Roll Your Own

The basic API for an adapter is this:

* `get(key)` - Get the value for a key.
* `set(key, value)` - Set the value for a key.
* `del(key)` - Delete the value for a key.

If you would like to make your own adapter, there are shared adapter specs (RSpec) and tests (MiniTest) that you can use to verify that you have everything working correctly.

A good place to start when creating your own adapter is to copy one of the adapters mentioned above and replace the client specific code with whatever client you are attempting to adapt.

### RSpec

For example, here is what the in-memory adapter spec looks like:

`spec/flipper/adapters/v2/memory_spec.rb`

```ruby
require 'helper'
require 'flipper/adapters/v2/memory'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::Memory do
  subject { described_class.new }

  it_should_behave_like 'a v2 flipper adapter'
end

```

### MiniTest

Here is what an in-memory adapter MiniTest looks like:

`test/adapters/v2/memory_test.rb`

```ruby
require 'test_helper'
require 'flipper/test/v2_shared_adapter_test'
require 'flipper/adapters/v2/memory'

class V2MemoryTest < MiniTest::Test
  prepend Flipper::Test::V2SharedAdapterTests

  def setup
    # Any code here will run before each test
    @adapter = Flipper::Adapters::V2::Memory.new
  end

  def teardown
    # Any code here will run after each test
  end
end
```
