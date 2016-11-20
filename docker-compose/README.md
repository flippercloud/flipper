### ============= Using ===================
1. Mount submodule: git submodule add git@bitbucket.org:forgesp/docker-compose.git docker-compose
2. Create docker compose file with 'app' section:
3. Utils for app:

  * docker-compose/bin/bash - run bash shell for app container

  ```sh
  docker-compose/bin/bash
  ```

  * docker-compose/bin/bower - run command with 'bower' gem

  ```sh
  docker-compose/bin/bower install
  ```

  * docker-compose/bin/bundle - run bundle wrapper

  ```sh
  docker-compose/bin/bundle update <super_gem>
  ```

  * docker-compose/bin/call - run command in working dir

  ```sh
  docker-compose/bin/call bin/db/prepare RACK_ENV=test
  ```

  * docker-compose/bin/rake - run rake command

  ```sh
  docker-compose/bin/rake db:seed
  ```

  * docker-compose/bin/rspec - run rspec command or bin/rspec if it exists

  ```sh
  docker-compose/bin/rspec spec/packages/events
  ```

