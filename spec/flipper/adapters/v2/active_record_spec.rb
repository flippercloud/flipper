require 'helper'
require 'flipper/adapters/v2/active_record'
require 'flipper/spec/shared_adapter_specs'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

require 'generators/flipper/templates/v2_migration'

RSpec.describe Flipper::Adapters::V2::ActiveRecord do
  subject { described_class.new }

  before(:all) do
    ActiveRecord::Base.establish_connection({
      adapter: "sqlite3",
      database: ":memory:",
    })
  end

  before(:each) do
    CreateFlipperV2Tables.up
  end

  after(:each) do
    CreateFlipperV2Tables.down
  end

  it_should_behave_like 'a v2 flipper adapter'
end
