#!/usr/bin/env rake
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'rake/testtask'
require 'flipper/version'

# gem install pkg/*.gem
# gem uninstall flipper flipper-ui flipper-redis
desc 'Build gem into the pkg directory'
task :build do
  FileUtils.rm_rf('pkg')
  Dir['*.gemspec'].each do |gemspec|
    system "gem build #{gemspec}"
  end
  FileUtils.mkdir_p('pkg')
  FileUtils.mv(Dir['*.gem'], 'pkg')
end

desc 'Tags version, pushes to remote, and pushes gem'
task release: :build do
  sh 'git', 'tag', "v#{Flipper::VERSION}"
  sh 'git push origin main'
  sh "git push origin v#{Flipper::VERSION}"
  puts "\nWhat OTP code should be used?"
  otp_code = STDIN.gets.chomp
  sh "ls pkg/*.gem | xargs -n 1 gem push --otp #{otp_code}"
end

namespace :expressions do
  desc 'Vendor JSON Schema files from the flippercloud/expressions repo ' \
       '(defaults to a sibling ../expressions checkout; override with SOURCE=/path/to/expressions)'
  task :vendor do
    require 'fileutils'

    source = ENV.fetch('SOURCE') { File.expand_path('../expressions', __dir__) }
    schemas_source = File.join(source, 'schemas')

    unless File.directory?(schemas_source)
      abort "No schemas found at #{schemas_source}. Pass SOURCE=/path/to/expressions."
    end

    dest = File.expand_path('lib/flipper/expression/schemas', __dir__)
    FileUtils.mkdir_p(dest)
    FileUtils.rm(Dir[File.join(dest, '*.json')])
    FileUtils.cp(Dir[File.join(schemas_source, '*.json')], dest)
    puts "Vendored #{Dir[File.join(dest, '*.json')].size} schema(s) into #{dest}"

    # Examples are shared test cases (valid/invalid + expected results) used by
    # spec/flipper/expression/schema_spec.rb so Ruby and JS test the same cases.
    examples_source = File.join(source, 'examples')
    if File.directory?(examples_source)
      examples_dest = File.expand_path('spec/fixtures/expressions/examples', __dir__)
      FileUtils.mkdir_p(examples_dest)
      FileUtils.rm(Dir[File.join(examples_dest, '*.json')])
      FileUtils.cp(Dir[File.join(examples_source, '*.json')], examples_dest)
      puts "Vendored #{Dir[File.join(examples_dest, '*.json')].size} example(s) into #{examples_dest}"
    end
  end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w(--color)
  t.verbose = false
end

namespace :spec do
  desc 'Run specs for UI queue'
  RSpec::Core::RakeTask.new(:ui) do |t|
    t.rspec_opts = %w(--color)
    t.pattern = ['spec/flipper/ui/**/*_spec.rb', 'spec/flipper/ui_spec.rb']
  end
end

Rake::TestTask.new do |t|
  t.libs = %w(lib test)
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
end

Rake::TestTask.new(:test_rails) do |t|
  t.libs = %w(lib test_rails)
  t.pattern = 'test_rails/**/*_test.rb'
  t.warning = false
end

task default: [:spec, :test, :test_rails]
