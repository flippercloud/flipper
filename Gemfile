source 'https://rubygems.org'
gemspec :name => 'flipper'

Dir['flipper-*.gemspec'].each do |gemspec|
  plugin = gemspec.scan(/flipper-(.*)\.gemspec/).flatten.first
  gemspec(:name => "flipper-#{plugin}", :development_group => plugin)
end

gem 'rake', '~> 10.4.2'
gem 'metriks', '~> 0.9.9'
gem 'shotgun', '~> 0.9'
gem 'statsd-ruby', '~> 1.2.1'
gem 'rspec', '~> 3.0'
gem 'rack-test', '~> 0.6.3'
gem 'activesupport', '~> 4.2.0'
gem 'sqlite3', '~> 1.3.11'
gem 'rails', "~> #{ENV["RAILS_VERSION"] || '4.2.0'}"

group(:guard) do
  gem 'guard', '~> 2.12.5'
  gem 'guard-rspec', '~> 4.5.0'
  gem 'guard-bundler', '~> 2.1.0'
  gem 'guard-coffeescript', '~> 2.0.1'
  gem 'guard-sass', '~> 1.6.0'
  gem 'rb-fsevent', '~> 0.9.4'
end
