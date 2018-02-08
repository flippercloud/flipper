# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

rspec_options = {
  all_after_pass: false,
  all_on_start: false,
  failed_mode: :keep,
  cmd: 'bundle exec rspec',
}

guard 'rspec', rspec_options do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(/shared_adapter_specs\.rb$/) { 'spec' }
  watch('spec/helper.rb') { 'spec' }
end

coffeescript_options = {
  input: 'lib/flipper/ui/assets/javascripts',
  output: 'lib/flipper/ui/public/js',
  patterns: [%r{^lib/flipper/ui/assets/javascripts/(.+\.(?:coffee|coffee\.md|litcoffee))$}],
}

guard 'coffeescript', coffeescript_options do
  coffeescript_options[:patterns].each { |pattern| watch(pattern) }
end

sass_options = {
  input: 'lib/flipper/ui/assets/stylesheets',
  output: 'lib/flipper/ui/public/css',
}
guard 'sass', sass_options
