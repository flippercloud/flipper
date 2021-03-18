# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

flipper_cloud_files = lambda do |file|
  file =~ /cloud/
end

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = ['nunemaker@gmail.com']
  gem.summary       = 'FeatureFlipper.com adapter for Flipper'
  gem.license       = 'MIT'
  gem.homepage      = 'https://github.com/jnunemaker/flipper'

  extra_files = [
    'lib/flipper/version.rb',
  ]
  gem.files         = `git ls-files`.split("\n").select(&flipper_cloud_files) + extra_files
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n").select(&flipper_cloud_files)
  gem.name          = 'flipper-cloud'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
end
