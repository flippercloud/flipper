# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

plugin_files = []
plugin_test_files = []

Dir['flipper-*.gemspec'].map do |gemspec|
  spec = Gem::Specification.load(gemspec)
  plugin_files << spec.files
  plugin_test_files << spec.files
end

ignored_files = plugin_files
ignored_files << Dir['script/*']
ignored_files << '.gitignore'
ignored_files << 'Guardfile'
ignored_files.flatten!.uniq!

ignored_test_files = plugin_test_files
ignored_test_files.flatten!.uniq!

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = 'support@flippercloud.io'
  gem.summary       = 'Beautiful, performant feature flags for Ruby and Rails.'
  gem.homepage      = 'https://www.flippercloud.io/docs'
  gem.license       = 'MIT'

  gem.bindir = "exe"
  gem.executables   = `git ls-files -- exe/*`.split("\n").map { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n") - ignored_files + ['lib/flipper/version.rb']
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n") - ignored_test_files
  gem.name          = 'flipper'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'concurrent-ruby', '< 2'

  gem.required_ruby_version = ">= #{Flipper::REQUIRED_RUBY_VERSION}"
end
