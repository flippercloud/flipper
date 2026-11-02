source 'https://rubygems.org'
gemspec name: 'flipper'

Dir['flipper-*.gemspec'].each do |gemspec|
  plugin = gemspec.scan(/flipper-(.*)\.gemspec/).flatten.first
  gemspec(name: "flipper-#{plugin}", development_group: plugin)
end

# Rails < 7.1 doesn't load logger itself, which concurrent-ruby 1.3.5 stopped doing for it.
if ENV['RAILS_VERSION'] && ENV['RAILS_VERSION'] != 'main' && Gem::Version.new(ENV['RAILS_VERSION']) < Gem::Version.new('7.1')
  gem 'concurrent-ruby', '1.3.4'
end
gem 'connection_pool'
gem 'debug'
gem 'rake'
gem 'statsd-ruby', '~> 1.2.1'
gem 'rspec', '~> 3.0'
gem 'rack-test'
gem 'rackup', '= 1.0.0'
gem 'sqlite3', "~> #{ENV['SQLITE3_VERSION'] || '2.1.0'}"
if ENV['RAILS_VERSION'] == 'main'
  gem 'rails', github: 'rails/rails', branch: 'main'
else
  gem 'rails', "~> #{ENV['RAILS_VERSION'] || '8.0'}"
end
gem 'minitest', '~> 5.18'
gem 'webmock'
gem 'ice_age'
gem 'webrick'
gem 'stackprof'
gem 'benchmark-ips'
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
