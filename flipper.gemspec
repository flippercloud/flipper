# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Nunemaker"]
  gem.email         = ["nunemaker@gmail.com"]
  gem.summary       = %q{Feature flipper for ANYTHING}
  gem.description   = %q{Feature flipper is the act of enabling/disabling features in your application, ideally without re-deploying or changing anything in your code base. Flipper makes this extremely easy to do with any backend you would like to use.}
  gem.homepage      = "http://jnunemaker.github.com/flipper"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "flipper"
  gem.require_paths = ["lib"]
  gem.version       = Flipper::VERSION
  gem.license       = "MIT"
end
