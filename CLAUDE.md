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

### Building and Releasing
- `bundle exec rake build` - Build all gems into pkg/ directory
- `bundle exec rake release` - Tag version, push to remote, and push gems (requires OTP)

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

### Testing

Uses both RSpec (currently preferred for new tests) and Minitest. Shared adapter specs ensure consistency across all storage backends. Extensive testing across multiple Rails versions (5.0-8.0).
