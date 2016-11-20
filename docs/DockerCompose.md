# Docker Compose for contributors

This gem includes different adapters which require specific tools instaled
on local machine. With docker this could be achieved inside container and
new contributor could start working on code with a minumum efforts.

## Steps:

1. Install Docker Compose https://docs.docker.com/compose/install
2. Install gems `docker-compose run --rm app bundle install`
3. Run specs `docker-compose run --rm app bundle exec rspec`
4. Clear and check files with Rubocop `docker-compose run --rm  app bundle exec rubocop -D`
5. Optional: log in to container an using a bash for running specs
```sh
docker-compose run --rm app bash
bundle exec rspec
```
