# -*- encoding: utf-8 -*-
# frozen_string_literal: true

require File.expand_path('lib/flipper/version', __dir__)
require File.expand_path('lib/flipper/metadata', __dir__)

flipper_api_files = lambda do |file|
  file =~ %r{(flipper)[\/-]api}
end

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = ['nunemaker@gmail.com']
  gem.summary       = 'API for the Flipper gem'
  gem.description   = 'Rack middleware that provides an API for the flipper gem.'
  gem.license       = 'MIT'
  gem.homepage      = 'https://github.com/jnunemaker/flipper'
  gem.files         = `git ls-files`.split("\n").select(&flipper_api_files) + ['lib/flipper/version.rb']
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n").select(&flipper_api_files)
  gem.name          = 'flipper-api'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
  gem.add_dependency 'rack', '>= 1.4', '< 3'
end
