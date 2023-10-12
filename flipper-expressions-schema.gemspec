# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = 'support@flippercloud.io'
  gem.summary       = 'ActiveRecord adapter for Flipper'
  gem.license       = 'MIT'
  gem.homepage      = 'https://www.flippercloud.io/docs/expressions'

  gem.files         = [
    'lib/flipper-expressions-schema.rb',
    'lib/flipper/expression/schema.rb',
    'lib/flipper/version.rb',
  ] + Dir['node_modules/@flippercloud.io/expressions/schemas/*.json']
  gem.name          = 'flipper-expressions-schema'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
  gem.add_dependency 'json_schemer', '~> 1.0'
end
