require "helper"
require "generators/flipper/update_generator"

class UpdateGeneratorTest < Rails::Generators::TestCase
  tests Flipper::Generators::UpdateGenerator
  ROOT = File.expand_path("../../../../tmp/generators", __FILE__)
  destination ROOT
  setup :prepare_destination

  setup do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
  end

  teardown do
    ActiveRecord::Base.connection.close
  end

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

    require_migrations

    silence { CreateFlipperTables.migrate(:up) }
    assert ActiveRecord::Base.connection.table_exists?(:flipper_features)
    assert ActiveRecord::Base.connection.table_exists?(:flipper_gates)

    assert ActiveRecord::Base.connection.column_exists?(:flipper_gates, :value, :string)
    silence { ChangeFlipperGatesValueToText.migrate(:up) }
    assert ActiveRecord::Base.connection.column_exists?(:flipper_gates, :value, :text)

    silence { ChangeFlipperGatesValueToText.migrate(:down) }
    assert ActiveRecord::Base.connection.column_exists?(:flipper_gates, :value, :string)

    silence { CreateFlipperTables.migrate(:down) }
    refute ActiveRecord::Base.connection.table_exists?(:flipper_features)
    refute ActiveRecord::Base.connection.table_exists?(:flipper_gates)
  end

  test "ChangeFlipperGatesValueToText is a noop if value is already text" do
    self.class.generator_class = Flipper::Generators::ActiveRecordGenerator
    run_generator

    self.class.generator_class = Flipper::Generators::UpdateGenerator
    run_generator

    assert_migration "db/migrate/create_flipper_tables.rb" do |migration|
      assert_method :up, migration do |up|
        assert_match(/text :value/, up)
      end
    end

    assert_migration "db/migrate/change_flipper_gates_value_to_text.rb"

    require_migrations

    silence { CreateFlipperTables.migrate(:up) }
    assert ActiveRecord::Base.connection.column_exists?(:flipper_gates, :value, :text)

    assert_nothing_raised do
      silence { ChangeFlipperGatesValueToText.migrate(:up) }
    end
    assert ActiveRecord::Base.connection.column_exists?(:flipper_gates, :value, :text)
  end

  def require_migrations
    # If these are not reloaded, then test order can cause failures
    Object.send(:remove_const, :CreateFlipperTables) if defined?(::CreateFlipperTables)
    Object.send(:remove_const, :ChangeFlipperGatesValueToText) if defined?(::ChangeFlipperGatesValueToText)

    Dir.glob("#{ROOT}/db/migrate/*.rb").each do |file|
      assert_nothing_raised do
        load file
      end
    end
  end
end
