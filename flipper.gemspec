# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Nunemaker"]
  gem.email         = ["nunemaker@gmail.com"]
  gem.description   = %q{Feature flipper for any adapter}
  gem.summary       = %q{Feature flipper for any adapter}
  gem.homepage      = "http://jnunemaker.github.com/flipper"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "flipper"
  gem.require_paths = ["lib"]
  gem.version       = Flipper::VERSION

  gem.add_dependency 'mongo', '~> 1.6'
  gem.add_dependency 'adapter', '~> 0.5'
end
