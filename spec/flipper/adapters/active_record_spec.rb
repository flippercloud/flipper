require 'flipper/adapters/active_record'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

RSpec.describe Flipper::Adapters::ActiveRecord do
  subject { described_class.new }

  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3',
                                            database: ':memory:')
  end

  before(:each) do
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE flipper_features (
        id integer PRIMARY KEY,
        key string NOT NULL UNIQUE,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE flipper_gates (
        id integer PRIMARY KEY,
        feature_key text NOT NULL,
        key string NOT NULL,
        value text DEFAULT NULL,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE UNIQUE INDEX index_gates_on_keys_and_value on flipper_gates (feature_key, key, value)
    SQL
  end

  after(:each) do
    ActiveRecord::Base.connection.execute("DROP table IF EXISTS `flipper_features`")
    ActiveRecord::Base.connection.execute("DROP table IF EXISTS `flipper_gates`")
  end

  it_should_behave_like 'a flipper adapter'

  it "should load actor ids fine" do
    flipper.enable_percentage_of_time(:foo, 1)

    ActiveRecord::Base.connection.execute <<-SQL
      INSERT INTO flipper_gates (feature_key, key, value, created_at, updated_at)
      VALUES ("foo", "actors", "Organization;4", time(), time())
    SQL

    flipper = Flipper.new(subject)
    flipper.preload([:foo])
  end

  context 'requiring "flipper-active_record"' do
    before do
      Flipper.configuration = nil
      Flipper.instance = nil

      silence_warnings { load 'flipper/adapters/active_record.rb' }
    end

    it 'configures itself' do
      expect(Flipper.adapter.adapter).to be_a(Flipper::Adapters::ActiveRecord)
    end
  end
end
