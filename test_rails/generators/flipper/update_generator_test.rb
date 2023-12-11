require "helper"
require "generators/flipper/update_generator"

class BasicsGeneratorTest < Rails::Generators::TestCase
  tests Flipper::Generators::UpdateGenerator
  destination File.expand_path("../../../../tmp", __FILE__)
  setup :prepare_destination

  test "generates migrations" do
    run_generator

    assert_migration "db/migrate/create_flipper_tables.rb" do |migration|
      assert_method :up, migration do |up|
        assert_match(/create_table :flipper_features/, up)
        assert_match(/create_table :flipper_gates/, up)
      end

      assert_method :down, migration do |down|
        assert_match(/drop_table :flipper_features/, down)
        assert_match(/drop_table :flipper_gates/, down)
      end
    end

    assert_migration "db/migrate/change_flipper_gates_value_to_text.rb" do |migration|
      [:up, :down].each do |dir|
        assert_method :up, migration do |method|
          assert_match(/change_column/, method)
        end
      end
    end
  end
end
