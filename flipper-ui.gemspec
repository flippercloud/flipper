# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/ui/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Nunemaker"]
  gem.email         = ["nunemaker@gmail.com"]
  gem.summary       = "UI for the Flipper gem"
  gem.description   = "Rack middleware that provides a fully featured web interface for the flipper gem."
  gem.license       = "MIT"
  gem.homepage      = "https://github.com/jnunemaker/flipper-ui"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "flipper-ui"
  gem.require_paths = ["lib"]
  gem.version       = Flipper::UI::VERSION

  gem.add_dependency 'rack', '~> 1.4', '< 1.7'
  gem.add_dependency 'rack-protection', '~> 1.5.3'
  gem.add_dependency 'flipper', '~> 0.7.0.beta3'
  gem.add_dependency 'erubis', '~> 2.7.0'
end
