require 'helper'
require 'flipper/adapters/active_record'
require 'flipper/spec/shared_adapter_specs'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

require 'generators/flipper/templates/migration'

RSpec.describe Flipper::Adapters::ActiveRecord do
  subject { described_class.new }

  before(:all) do
    ActiveRecord::Base.establish_connection({
      adapter: "sqlite3",
      database: ":memory:",
    })
  end

  before(:each) do
    CreateFlipperTables.up
  end

  after(:each) do
    CreateFlipperTables.down
  end

  it_should_behave_like 'a flipper adapter'
end
