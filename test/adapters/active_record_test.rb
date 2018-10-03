require 'test_helper'
require 'flipper/test/shared_adapter_test'
require 'flipper/adapters/active_record'

class ActiveRecordTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    DataStores.reset_active_record
    @adapter = Flipper::Adapters::ActiveRecord.new
  end

  def test_models_honor_table_name_prefixes_and_suffixes
    ActiveRecord::Base.table_name_prefix = :foo_
    ActiveRecord::Base.table_name_suffix = :_bar

    Flipper::Adapters::ActiveRecord.send(:remove_const, :Feature)
    Flipper::Adapters::ActiveRecord.send(:remove_const, :Gate)
    load("flipper/adapters/active_record.rb")

    assert_equal "foo_flipper_features_bar", Flipper::Adapters::ActiveRecord::Feature.table_name
    assert_equal "foo_flipper_gates_bar", Flipper::Adapters::ActiveRecord::Gate.table_name

  ensure
    ActiveRecord::Base.table_name_prefix = ""
    ActiveRecord::Base.table_name_suffix = ""

    Flipper::Adapters::ActiveRecord.send(:remove_const, :Feature)
    Flipper::Adapters::ActiveRecord.send(:remove_const, :Gate)
    load("flipper/adapters/active_record.rb")
  end
end
