# Flipper read-only

A [read-only](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/read_only.rb) adapter for [Flipper](https://github.com/jnunemaker/flipper).

Use this adapter to wrap another adapter and raise an exception for any writes.

Any attempted write raises `Flipper::Adapters::ReadOnly::WriteAttempted`  with message  `'write attempted while in read only mode'`

## Usage

```ruby
# example wrapping memory adapter
require 'flipper/adapters/read_only'

Flipper.configure do |config|
  config.adapter do
    Flipper::Adapters::ReadOnly.new(Flipper::Adapters::Memory.new)
  end
end

# Enabling a feature
> Flipper[:dashboard_panel].enable
=> Flipper::Adapters::ReadOnly::WriteAttempted: write attempted while in read only mode
```
