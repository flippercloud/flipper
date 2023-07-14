# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = 'support@flippercloud.io'
  gem.summary       = 'Feature flags for gradual rollouts, maintenance, experiments, and more…'
  gem.homepage      = 'https://www.flippercloud.io'
  gem.license       = 'MIT'
  gem.files         = ['lib/flipper/version.rb']
  gem.require_paths = ['lib']

  gem.name          = 'flipper-rails'
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
  gem.add_dependency 'flipper-active_record', "~> #{Flipper::VERSION}"
  gem.add_dependency 'flipper-cloud', "~> #{Flipper::VERSION}"
end
