$:.unshift(File.expand_path('../../lib', __FILE__))

require 'pathname'
require 'logger'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
log_path  = root_path.join('log')
log_path.mkpath

require 'rubygems'
require 'bundler'

Bundler.require(:default, :test)

require 'flipper'

Logger.new(log_path.join('test.log'))

RSpec.configure do |config|
  config.filter_run :focused => true
  config.alias_example_to :fit, :focused => true
  config.alias_example_to :xit, :disabled => true
  config.run_all_when_everything_filtered = true
end

shared_examples_for 'a percentage' do
  it "initializes with value" do
    percentage = described_class.new(12)
    percentage.should be_instance_of(described_class)
  end

  it "converts string values to integers when initializing" do
    percentage = described_class.new('15')
    percentage.value.should eq(15)
  end

  it "has a value" do
    percentage = described_class.new(19)
    percentage.value.should eq(19)
  end
end
