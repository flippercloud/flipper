source 'https://rubygems.org'
gemspec name: 'flipper'

Dir['flipper-*.gemspec'].each do |gemspec|
  plugin = gemspec.scan(/flipper-(.*)\.gemspec/).flatten.first
  gemspec(name: "flipper-#{plugin}", development_group: plugin)
end

rails_version = ENV['RAILS_VERSION'] || '8.0'
sqlite3_version = ENV['SQLITE3_VERSION'] || case rails_version
when /8\.\d+/
  '2.1.0'
when /7\.\d+/
  '1.4.1'
when /6\.\d+/
  '1.4.1'
when /5\.\d+/
  '1.3.11'
end

gem 'debug'
gem 'rake'
gem 'statsd-ruby', '~> 1.2.1'
gem 'rspec', '~> 3.0'
gem 'rack-test'
gem 'rackup'
gem 'sqlite3', "~> #{sqlite3_version}"
gem 'rails', "~> #{rails_version}"
gem 'minitest', '~> 5.18'
gem 'minitest-documentation'
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

group(:guard) do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'rb-fsevent'
end
