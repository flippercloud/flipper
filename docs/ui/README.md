# Flipper::UI

UI for the [Flipper](https://github.com/jnunemaker/flipper) gem.

## Screenshots

Viewing list of features:
![features](images/features.png)

Viewing an individual feature:
![feature](images/feature.png)

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-ui'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install flipper-ui

## Usage

### Rails

Given that you've already initialized `Flipper` as per the [flipper](https://github.com/jnunemaker/flipper) readme:

```ruby
# config/initializers/flipper.rb
$flipper = Flipper.new(...)
```

you can mount `Flipper::UI` to a route of your choice:
```ruby
# config/routes.rb

YourRailsApp::Application.routes.draw do
  mount Flipper::UI.app($flipper, secret: "_your_session_secret") => '/flipper'
end
```

#### Security

You almost certainly want to limit access when using Flipper::UI in production. Using [routes constraints](http://guides.rubyonrails.org/routing.html#request-based-constraints) is one way to achieve this:

```ruby
# config/routes.rb

flipper_constraint = lambda { |request| request.remote_ip == '127.0.0.1' }
constraints flipper_constraint do
  mount Flipper::UI.app($flipper, secret: "_your_session_secret") => '/flipper'
end
```

Another example of a route constrain using the current_user when using Devise or another warden based authentication system:

```ruby
# initializers/admin_access.rb

class CanAccessFlipperUI
  def self.matches?(request)
    current_user = request.env['warden'].user
    current_user.present? && current_user.respond_to?(:admin?) && current_user.admin?
  end
end

# config/routes.rb

constraints CanAccessFlipperUI do
  mount Flipper::UI.app($flipper, secret: "_your_session_secret") => '/flipper'
end
```


### Standalone

Minimal example for Rack:

```ruby
# config.ru

require 'flipper-ui'
require 'flipper/adapters/memory'

adapter = Flipper::Adapters::Memory.new
flipper = Flipper.new(adapter)

run Flipper::UI.app(flipper, secret: "_your_session_secret")
```

See [examples/ui/basic.ru](https://github.com/jnunemaker/flipper/blob/master/examples/ui/basic.ru) for a more full example

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. **Fire up the app** (`script/server`)
4. **Start up guard** (`bundle exec guard` for automatic coffeescript/sass compilation and such).
5. Commit your changes (`git commit -am 'Added some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create new Pull Request
