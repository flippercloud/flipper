# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = 'support@flippercloud.io'
  gem.summary       = '[DEPRECATED] This gem has been merged into the `flipper` gem'
  gem.license       = 'MIT'
  gem.homepage      = 'https://www.flippercloud.io'

  gem.files         = [ 'lib/flipper-cloud.rb', 'lib/flipper/version.rb' ]
  gem.name          = 'flipper-cloud'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
end
