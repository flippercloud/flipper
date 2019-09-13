# -*- encoding: utf-8 -*-
# frozen_string_literal: true

require File.expand_path('lib/flipper/version', __dir__)
require File.expand_path('lib/flipper/metadata', __dir__)

flipper_active_record_files = lambda do |file|
  file =~ /active_record/
end

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = ['nunemaker@gmail.com']
  gem.summary       = 'ActiveRecord adapter for Flipper'
  gem.description   = 'ActiveRecord adapter for Flipper'
  gem.license       = 'MIT'
  gem.homepage      = 'https://github.com/jnunemaker/flipper'

  extra_files = [
    'lib/generators/flipper/templates/migration.erb',
    'lib/flipper/version.rb',
  ]
  gem.files         = `git ls-files`.split("\n").select(&flipper_active_record_files) + extra_files
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n").select(&flipper_active_record_files)
  gem.name          = 'flipper-active_record'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'activerecord', '>= 4.2', '< 7'
  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
end
