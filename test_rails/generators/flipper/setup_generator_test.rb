require "helper"
require "generators/flipper/setup_generator"

class SetupGeneratorTest < Rails::Generators::TestCase
  tests Flipper::Generators::SetupGenerator
  ROOT = File.expand_path("../../../tmp/generators", __dir__)
  destination ROOT
  setup :prepare_destination

  test "invokes flipper:active_record generator if ActiveRecord adapter defined" do
    begin
      load 'flipper/adapters/active_record.rb'
      run_generator
      assert_migration "db/migrate/create_flipper_tables.rb"
    ensure
      Flipper::Adapters.send(:remove_const, :ActiveRecord)
    end
  end

  test "does not invoke flipper:active_record generator if ActiveRecord adapter not defined" do
    # Ensure adapter not defined
    Flipper::Adapters.send(:remove_const, :ActiveRecord) rescue nil

    run_generator
    assert_no_migration "db/migrate/create_flipper_tables.rb"
  end
end
