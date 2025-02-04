[![Flipper Mark](docs/images/banner.jpg)](https://www.flippercloud.io)

[Website](https://flippercloud.io?utm_source=oss&utm_medium=readme&utm_campaign=website_link) | [Documentation](https://flippercloud.io/docs?utm_source=oss&utm_medium=readme&utm_campaign=docs_link) | [Examples](examples) | [Chat](https://chat.flippercloud.io/join/xjHq-aJsA-BeZH) | [Twitter](https://twitter.com/flipper_cloud) | [Ruby.social](https://ruby.social/@flipper)

# Flipper

> Beautiful, performant feature flags for Ruby and Rails.

Flipper gives you control over who has access to features in your app.

- Enable or disable features for everyone, specific actors, groups of actors, a percentage of actors, or a percentage of time.
- Configure your feature flags from the console or a web UI.
- Regardless of what data store you are using, Flipper can performantly store your feature flags.
- Use [Flipper Cloud](#flipper-cloud) to cascade features from multiple environments, share settings with your team, control permissions, keep an audit history, and rollback.

Control your software &mdash; don't let it control you.

## Installation

Add this line to your application's Gemfile:

    gem 'flipper'

You'll also want to pick a storage [adapter](https://flippercloud.io/docs/adapters), for example:

    gem 'flipper-active_record'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper

## Subscribe &amp; Ship

[💌 &nbsp;Subscribe](https://blog.flippercloud.io/#/portal/signup) - we'll send you short and sweet emails when we release new versions ([examples](https://blog.flippercloud.io/tag/releases/)).

## Getting Started

Use `Flipper#enabled?` in your app to check if a feature is enabled.

```ruby
# check if search is enabled
if Flipper.enabled?(:search, current_user)
  puts 'Search away!'
else
  puts 'No search for you!'
end
```

All features are disabled by default, so you'll need to explicitly enable them.

```ruby
# Enable a feature for everyone
Flipper.enable :search

# Enable a feature for a specific actor
Flipper.enable_actor :search, current_user

# Enable a feature for a group of actors
Flipper.enable_group :search, :admin

# Enable a feature for a percentage of actors
Flipper.enable_percentage_of_actors :search, 2
```

Read more about [getting started with Flipper](https://flippercloud.io/docs?utm_source=oss&utm_medium=readme&utm_campaign=getting_started) and [enabling features](https://flippercloud.io/docs/features?utm_source=oss&utm_medium=readme&utm_campaign=enabling_features).

## Flipper Cloud

Like Flipper and want more? Check out [Flipper Cloud](https://www.flippercloud.io?utm_source=oss&utm_medium=readme&utm_campaign=check_out), which comes with:

- **multiple environments** &mdash; production, staging, per continent, whatever you need. Every environment inherits from production by default and every project comes with a [project overview page](https://blog.flippercloud.io/project-overview/) that shows each feature and its status in each environment.
- **personal environments** &mdash; everyone on your team gets a personal environment (that inherits from production) which they can modify however they want without stepping on anyone else's toes.
- **permissions** &mdash; grant access to everyone in your organization or lockdown each project to particular people. You can even limit access to a particular environment (like production) to specific people.
- **audit history** &mdash; every feature change and who made it.
- **rollbacks** &mdash; enable or disable a feature accidentally? No problem. You can roll back to any point in the audit history with a single click.
- **maintenance** &mdash; we'll keep the lights on for you. We also have handy webhooks and background polling for keeping your app in sync with Cloud, so **our availability won't affect yours**. All your feature flag reads are local to your app.
- **everything in one place** &mdash; no need to bounce around from different application UIs or IRB consoles.

[![Flipper Cloud Screenshot](docs/images/flipper_cloud.png)](https://www.flippercloud.io?utm_source=oss&utm_medium=readme&utm_campaign=screenshot)

Cloud is super simple to integrate with Rails ([demo app](https://github.com/fewerandfaster/flipper-rails-demo)), Sinatra or any other framework.

We also have a [free plan](https://www.flippercloud.io?utm_source=oss&utm_medium=readme&utm_campaign=free_plan) that you can use forever.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run the tests (`bundle exec rake`). Check out [Docker-Compose](docs/DockerCompose.md) if you need help getting all the adapters running.
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

## Releasing

1. Update the version to be whatever it should be and commit.
2. `script/release`
3. Create a new [GitHub Release](https://github.com/flippercloud/flipper/releases/new)

## Brought To You By

| pic                                                                    | @mention                                       | area        |
| ---------------------------------------------------------------------- | ---------------------------------------------- | ----------- |
| ![@jnunemaker](https://avatars3.githubusercontent.com/u/235?s=64)      | [@jnunemaker](https://github.com/jnunemaker)   | most things |
| ![@bkeepers](https://avatars3.githubusercontent.com/u/173?s=64)        | [@bkeepers](https://github.com/bkeepers)       | most things |
| ![@dpep](https://avatars3.githubusercontent.com/u/918804?s=64)         | [@dpep](https://github.com/dpep)               | tbd         |
| ![@alexwheeler](https://avatars3.githubusercontent.com/u/3260042?s=64) | [@alexwheeler](https://github.com/alexwheeler) | api         |
| ![@thetimbanks](https://avatars1.githubusercontent.com/u/471801?s=64)  | [@thetimbanks](https://github.com/thetimbanks) | ui          |
| ![@lazebny](https://avatars1.githubusercontent.com/u/6276766?s=64)     | [@lazebny](https://github.com/lazebny)         | docker      |
| ![@pagertree](https://avatars.githubusercontent.com/u/24941240?s=64)   | [@pagertree](https://github.com/pagertree)   | sponsor     |
| ![@kdaigle](https://avatars.githubusercontent.com/u/2501?s=64)   | [@kdaigle](https://github.com/kdaigle)   | sponsor     |
