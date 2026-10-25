# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

flipper_mongo_files = lambda do |file|
  file =~ /mongo/
end

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = 'support@flippercloud.io'
  gem.summary       = 'Mongo feature flag adapter for Flipper'
  gem.license       = 'MIT'
  gem.homepage      = 'https://www.flippercloud.io/docs/adapters/mongo'

  gem.files         = `git ls-files -- lib`.split("\n").select(&flipper_mongo_files) + ['lib/flipper/version.rb']
  gem.name          = 'flipper-mongo'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
  gem.add_dependency 'mongo', '~> 2.0'
end
