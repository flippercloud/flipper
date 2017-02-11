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
  watch(%r{^lib/(.*/)?([^/]+)\.rb$}) { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{shared_adapter_specs}) {
    Dir.glob("spec/flipper/adapters/*_spec.rb") +
      Dir.glob("spec/flipper/adapters/v2/*_spec.rb")
  }
  watch('spec/helper.rb') { "spec" }
end

minitest_options = {
  :all_after_pass => false,
  :all_on_start   => false,
  :failed_mode    => :keep,
  :test_folders => ["test"],
}
guard :minitest, minitest_options do
  watch(%r{^test/(.*)\/?(.*)_test\.rb$})
  watch(%r{^lib/(.*/)?([^/]+)\.rb$}) { |m| "test/#{m[1]}#{m[2]}_test.rb" }
  watch(%r{^test/test_helper\.rb$}) { "test" }
  watch("lib/flipper/test/shared_adapter_test.rb") {
    Dir.glob("test/adapters/*_test.rb")
  }
  watch("lib/flipper/test/v2_shared_adapter_test.rb") {
    Dir.glob("test/adapters/v2/*_test.rb")
  }
end

coffee_options = {
  input: 'lib/flipper/ui/assets/javascripts',
  output: 'lib/flipper/ui/public/js',
  all_on_start: false,
}
guard 'coffeescript', coffee_options

sass_options = {
  input: 'lib/flipper/ui/assets/stylesheets',
  output: 'lib/flipper/ui/public/css',
}
guard 'sass', sass_options
