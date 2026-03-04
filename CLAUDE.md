# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
- `bundle exec rake` - Run all tests (RSpec, Minitest, and Rails tests)
- `bundle exec rspec` - Run RSpec tests only
- `bundle exec rake spec:ui` - Run UI-specific specs
- `bundle exec rake test` - Run Minitest tests only
- `bundle exec rake test_rails` - Run Rails generator tests
- `script/test` - Bootstrap and run tests across multiple Rails versions (5.0-8.0)

### Development Setup
- `script/bootstrap` - Bundle install dependencies and setup binstubs
- `script/console` - Start interactive console with Flipper loaded (uses Pry)
- `script/server` - Start local UI server on port 9999 for testing web interface

### Releasing
1. Bump version in `lib/flipper/version.rb`, commit, and push to main
2. Tag and push: `git tag v1.x.x && git push origin v1.x.x`
3. GitHub Actions (`.github/workflows/release.yml`) builds and publishes all 12 gems via RubyGems trusted publishing, then creates a draft GitHub Release
4. Edit and publish the draft release at https://github.com/flippercloud/flipper/releases

- `bundle exec rake build` - Build all gems locally into pkg/ directory
- `script/release` - Manual fallback for local releases (prompts for OTP)

**After releasing**, purge the cached release URLs on flippercloud.io:
- `/release`
- `/release.json`

## Architecture Overview

Flipper is a feature flag library for Ruby with a modular adapter-based architecture:

### Core Components

**DSL Layer** (`lib/flipper/dsl.rb`):
- Main interface for feature flag operations
- Delegates to Feature instances
- Handles memoization and instrumentation
- Thread-safe instance management

**Feature** (`lib/flipper/feature.rb`):
- Represents individual feature flags
- Manages enable/disable operations through gates
- Handles instrumentation events
- Works with adapters for persistence

**Adapters** (`lib/flipper/adapters/`):
- Pluggable storage backends (Redis, ActiveRecord, Memory, etc.)
- Common interface for all storage implementations
- Support for caching, failover, and synchronization patterns

**Gates** (`lib/flipper/gates/`):
- Different targeting mechanisms:
  - Boolean (on/off for everyone)
  - Actor (specific users/entities)
  - Group (predefined user groups)
  - Percentage of Actors (rollout to X% of users)
  - Percentage of Time (probabilistic enabling)
  - Expression (complex conditional logic)

### Multi-Gem Structure

The project is structured as multiple gems:
- `flipper` - Core library
- `flipper-ui` - Web interface
- `flipper-api` - REST API
- `flipper-cloud` - Cloud service integration
- `flipper-*` - Various adapter gems (redis, active_record, mongo, etc.)

### Key Patterns

**Configuration**: Global configuration through `Flipper.configure` with per-thread instances
**Instrumentation**: Built-in event system for monitoring and debugging
**Memoization**: Automatic caching of feature checks within request/thread scope
**Type Safety**: Strong typing system for actors, percentages, and other values

### Serialization and HTTP

Use `Flipper::Typecast` for JSON and gzip serialization instead of calling `JSON.generate`/`JSON.parse` or `Zlib` directly:
- `Typecast.to_json(hash)` / `Typecast.from_json(string)` for JSON serialization
- `Typecast.to_gzip(string)` / `Typecast.from_gzip(string)` for gzip compression

For outbound HTTP requests, use `Flipper::Adapters::Http::Client` instead of raw `Net::HTTP`. It provides timeouts, retries (`max_retries`), SSL verification, and diagnostic headers (user-agent, client-language, client-platform, etc.). See `lib/flipper/cloud/migrate.rb` for an example.

### Testing

Uses both RSpec (currently preferred for new tests) and Minitest. Shared adapter specs ensure consistency across all storage backends. Extensive testing across multiple Rails versions (5.0-8.0).

`Flipper.configuration` is reset to nil before each spec (in `spec/spec_helper.rb`), but `Flipper::UI.configuration` is **not** globally reset. When modifying UI config in tests, set the value in `before` and reset it in `after` to match the existing pattern throughout the spec suite.
