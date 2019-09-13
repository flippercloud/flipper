<pre>
                                   __
                               _.-~  )
                    _..--~~~~,'   ,-/     _
                 .-'. . . .'   ,-','    ,' )
               ,'. . . _   ,--~,-'__..-'  ,'
             ,'. . .  (@)' ---~~~~      ,'
            /. . . . '~~             ,-'
           /. . . . .             ,-'
          ; . . . .  - .        ,'
         : . . . .       _     /
        . . . . .          `-.:
       . . . ./  - .          )
      .  . . |  _____..---.._/ _____
~---~~~~----~~~~             ~~
</pre>

Feature flipping is the act of enabling or disabling features or parts of your application, ideally without re-deploying or changing anything in your code base.

The goal of this gem is to make turning features on or off so easy that everyone does it. Whatever your data store, throughput, or experience, feature flipping should be easy and have minimal impact on your application.

## Installation

Add this line to your application's Gemfile:

    gem 'flipper'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper

## Examples

The goal of the API for flipper was to have everything revolve around features and what ways they can be enabled. Start with top level and dig into a feature, then dig in further and enable that feature for a given type of access, as opposed to thinking about how the feature will be accessed first (ie: `stats.enable` vs `activate_group(:stats, ...)`).

```ruby
require 'flipper'

Flipper.configure do |config|
  config.default do
    # pick an adapter, this uses memory, any will do
    adapter = Flipper::Adapters::Memory.new

    # pass adapter to handy DSL instance
    Flipper.new(adapter)
  end
end

# check if search is enabled
if Flipper.enabled?(:search)
  puts 'Search away!'
else
  puts 'No search for you!'
end

puts 'Enabling Search...'
Flipper.enable(:search)

# check if search is enabled
if Flipper.enabled?(:search)
  puts 'Search away!'
else
  puts 'No search for you!'
end
```

Of course there are more [examples for you to peruse](examples/). You could also check out the [DSL](lib/flipper/dsl.rb) and [Feature](lib/flipper/feature.rb) classes for code/docs.

## Docs

* [Gates](docs/Gates.md) - Boolean, Groups, Actors, % of Actors, and % of Time
* [Adapters](docs/Adapters.md) - Mongo, Redis, Cassandra, Active Record...
* [Instrumentation](docs/Instrumentation.md) - ActiveSupport::Notifications and Statsd
* [Optimization](docs/Optimization.md) - Memoization middleware and Cache adapters
* [Web Interface](docs/ui/README.md) - Point and click...
* [API](docs/api/README.md) - HTTP API interface
* [Caveats](docs/Caveats.md) - Flipper beware! (see what I did there)
* [Docker-Compose](docs/DockerCompose.md) - Using docker-compose in contributing

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run the tests (`bundle exec rake`)
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

## Releasing

1. Update the version to be whatever it should be and commit.
2. `script/release`
3. Profit.

## Brought To You By

| pic | @mention | area |
|---|---|---|
| ![@jnunemaker](https://avatars3.githubusercontent.com/u/235?s=64) | [@jnunemaker](https://github.com/jnunemaker) | most things |
| ![@alexwheeler](https://avatars3.githubusercontent.com/u/3260042?s=64) | [@alexwheeler](https://github.com/alexwheeler) | api |
| ![@thetimbanks](https://avatars1.githubusercontent.com/u/471801?s=64) | [@thetimbanks](https://github.com/thetimbanks) | ui |
| ![@lazebny](https://avatars1.githubusercontent.com/u/6276766?s=64) | [@lazebny](https://github.com/lazebny) | docker |
