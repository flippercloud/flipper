# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

flipper_api_files = lambda do |file|
  file =~ %r{(flipper)[\/-]api}
end

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = ['nunemaker@gmail.com']
  gem.summary       = 'API for the Flipper gem'
  gem.license       = 'MIT'
  gem.homepage      = 'https://github.com/jnunemaker/flipper'
  gem.files         = `git ls-files`.split("\n").select(&flipper_api_files) + ['lib/flipper/version.rb']
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n").select(&flipper_api_files)
  gem.name          = 'flipper-api'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'rack', '>= 1.4', '< 3'
  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
end
