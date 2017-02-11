class CreateFlipperTablesSequel < Sequel::Migration
  def up
    create_table :flipper_features do |_t|
      String :key, primary_key: true, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    create_table :flipper_gates do |_t|
      String :feature_key, null: false
      String :key, null: false
      String :value
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      primary_key [:feature_key, :key, :value]
    end
  end

  def down
    drop_table :flipper_gates
    drop_table :flipper_features
  end
end
