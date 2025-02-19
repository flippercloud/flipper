source 'https://rubygems.org'
gemspec name: 'flipper'

Dir['flipper-*.gemspec'].each do |gemspec|
  plugin = gemspec.scan(/flipper-(.*)\.gemspec/).flatten.first
  gemspec(name: "flipper-#{plugin}", development_group: plugin)
end

gem 'concurrent-ruby', '1.3.4'
gem 'connection_pool'
gem 'debug'
gem 'rake'
gem 'statsd-ruby', '~> 1.2.1'
gem 'rspec', '~> 3.0'
gem 'rack-test'
gem 'rackup', '= 1.0.0'
gem 'sqlite3', "~> #{ENV['SQLITE3_VERSION'] || '2.1.0'}"
gem 'rails', "~> #{ENV['RAILS_VERSION'] || '8.0'}"
gem 'minitest', '~> 5.18'
gem 'minitest-documentation'
gem 'pstore'
gem 'webmock'
gem 'ice_age'
gem 'redis-namespace'
gem 'webrick'
gem 'stackprof'
gem 'benchmark-ips'
gem 'stackprof-webnav'
gem 'flamegraph'
gem 'mysql2'
gem 'pg'
gem 'cuprite'
gem 'puma'
gem 'warning'

group(:guard) do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'rb-fsevent'
end
