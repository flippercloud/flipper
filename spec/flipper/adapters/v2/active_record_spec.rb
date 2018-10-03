require 'helper'
require 'flipper/adapters/v2/active_record'
require 'flipper/spec/shared_adapter_specs'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

RSpec.describe Flipper::Adapters::V2::ActiveRecord do
  subject { described_class.new }

  before(:each) do
    DataStores.reset_active_record
  end

  it_should_behave_like 'a v2 flipper adapter'
end
