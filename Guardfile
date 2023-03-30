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
  watch('lib/flipper/expression.rb') { 'spec/flipper_integration_spec.rb' }
  watch('lib/flipper/ui/middleware.rb') { 'spec/flipper/ui_spec.rb' }
  watch('lib/flipper/api/middleware.rb') { 'spec/flipper/api_spec.rb' }
  watch(/shared_adapter_specs\.rb$/) { 'spec' }
  watch('spec/helper.rb') { 'spec' }

  watch(%r{lib/flipper/expressions}) { 'spec/flipper/expressions_schema_spec.rb' }
  watch(%r{node_modules/@flippercloud.io/expressions}) { 'spec/flipper/expressions_schema_spec.rb' }

  # To run all specs on every change... (useful with focus and fit)
  # watch(%r{.*}) { 'spec' }
end
