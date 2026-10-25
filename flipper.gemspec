# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

plugin_files = Dir['flipper-*.gemspec'].flat_map { |gemspec| Gem::Specification.load(gemspec).files }

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = 'support@flippercloud.io'
  gem.summary       = 'Beautiful, performant feature flags for Ruby and Rails.'
  gem.homepage      = 'https://www.flippercloud.io/docs'
  gem.license       = 'MIT'

  gem.bindir = "exe"
  gem.executables   = `git ls-files -- exe/*`.split("\n").map { |f| File.basename(f) }
  # Ship only what apps load at runtime, not specs, examples, or dev tooling.
  gem.files         = `git ls-files -- lib exe README.md LICENSE Changelog.md`.split("\n") - plugin_files + ['lib/flipper/version.rb']
  gem.name          = 'flipper'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'concurrent-ruby', '< 2'

  gem.required_ruby_version = ">= #{Flipper::REQUIRED_RUBY_VERSION}"
end
