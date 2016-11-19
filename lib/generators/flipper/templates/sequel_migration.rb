class CreateFlipperTablesSequel < Sequel::Migration
  def up
    create_table :flipper_features do |t|
      String :key, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
    add_index :flipper_features, :key, unique: true

    create_table :flipper_gates do |t|
      String :feature_key, null: false
      String :key, null: false
      String :value
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
    add_index :flipper_gates, [:feature_key, :key, :value], unique: true
  end

  def down
    drop_table :flipper_gates
    drop_table :flipper_features
  end
end
