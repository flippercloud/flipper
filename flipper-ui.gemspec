# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

flipper_ui_files = lambda do |file|
  file =~ %r{(docs|examples|flipper)[\/-]ui}
end

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = 'support@flippercloud.io'
  gem.summary       = 'Feature flag UI for the Flipper gem'
  gem.license       = 'MIT'
  gem.homepage      = 'https://www.flippercloud.io/docs/ui'

  gem.files         = `git ls-files`.split("\n").select(&flipper_ui_files) + ['lib/flipper/version.rb']
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n").select(&flipper_ui_files)
  gem.name          = 'flipper-ui'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'rack', '>= 1.4', '< 4'
  gem.add_dependency 'rack-protection', '>= 1.5.3', '<5.0.0'
  gem.add_dependency 'rack-session', '>= 1.0.2', '< 3.0.0'
  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
  gem.add_dependency 'erubi', '>= 1.0.0', '< 2.0.0'
  gem.add_dependency 'sanitize', '< 8'
end
