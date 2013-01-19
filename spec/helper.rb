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
  config.fail_fast = true

  config.filter_run :focused => true
  config.alias_example_to :fit, :focused => true
  config.alias_example_to :xit, :pending => true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    Flipper.groups = nil
  end
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

  it "raises exception for value higher than 100" do
    expect {
      described_class.new(101)
    }.to raise_error(ArgumentError, "value must be a positive number less than or equal to 100, but was 101")
  end

  it "raises exception for negative value" do
    expect {
      described_class.new(-1)
    }.to raise_error(ArgumentError, "value must be a positive number less than or equal to 100, but was -1")
  end
end

shared_examples_for 'a DSL feature' do
  it "returns instance of feature" do
    feature.should be_instance_of(Flipper::Feature)
  end

  it "sets name" do
    feature.name.should eq(:stats)
  end

  it "sets adapter" do
    feature.adapter.should eq(dsl.adapter)
  end

  it "sets instrumentor" do
    feature.instrumentor.should eq(dsl.instrumentor)
  end

  it "memoizes the feature" do
    dsl.feature(:stats).should equal(feature)
  end
end
