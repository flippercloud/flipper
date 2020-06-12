# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)

flipper_moneta_files = lambda do |file|
  file =~ /moneta/
end

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = ['nunemaker@gmail.com']
  gem.summary       = 'Moneta adapter for Flipper'
  gem.license       = 'MIT'
  gem.homepage      = 'https://github.com/jnunemaker/flipper'

  gem.files         = `git ls-files`.split("\n").select(&flipper_moneta_files) + ['lib/flipper/version.rb']
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n").select(&flipper_moneta_files)
  gem.name          = 'flipper-moneta'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION

  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
  gem.add_dependency 'moneta', '>= 0.7.0', '< 1.2'
end
