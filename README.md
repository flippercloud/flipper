# Flipper

Feature flipper for any adapter.

## Usage


    require 'adapter/memory'

    adapter = Adapter[:memory].new({})
    search = Flipper::Feature.new(:search, adapter)

    if search.enabled?
      puts 'Search away!'
    else
      puts 'No search for you!'
    end

    puts 'Enabling Search...'
    search.enable

    if search.enabled?
      puts 'Search away!'
    else
      puts 'No search for you!'
    end


## Installation

Add this line to your application's Gemfile:

    gem 'flipper'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
