# Docker Compose for contributors

Flipper's adapters need Postgres, MySQL, Redis, MongoDB and Memcached for the
full test suite. Docker Compose runs all of them, plus Ruby, in containers, so
you don't have to install them locally. The Ruby and service versions match CI.

## Steps

1. Install Docker with Compose: https://docs.docker.com/compose/install
1. Build the app image: `docker compose build`
1. Install gems: `docker compose run --rm app bundle install`
1. Run everything CI runs (RSpec, Minitest, and Rails tests): `docker compose run --rm app bundle exec rake`
1. Or run part of it: `docker compose run --rm app bundle exec rspec spec/flipper/adapters/redis_spec.rb`
1. Optional: open a shell in the container to run commands there:

```sh
docker compose run --rm app bash
bundle exec rake
```

When you're done, `docker compose down` stops the services. Add `-v` to also
delete the installed gems.

The containers don't publish any ports, so they won't clash with Redis,
Postgres, etc. already running on your machine.
