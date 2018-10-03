# Require the migrations so we can use them
require 'active_record'
require 'redis'
require 'mongo'
require 'pstore'

module DataStores
  def self.redis
    @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
  end

  def self.reset_redis
    redis.flushdb
  end

  def self.mongo
    @mongo ||= begin
      Mongo::Logger.logger.level = Logger::INFO

      options = {
        server_selection_timeout: 1,
        database: 'testing',
      }
      client = Mongo::Client.new(["127.0.0.1:27017"], options)
      client['testing']
    end
  end

  def self.reset_mongo
    mongo.delete_many
  end

  def self.dalli
    @dalli ||= Dalli::Client.new(ENV.fetch('MEMCACHED_URL', 'localhost:11211'))
  end

  def self.reset_dalli
    dalli.flush
  end

  ACTIVE_RECORD_TABLES = %w(flipper_features flipper_gates flipper_keys).freeze

  def self.reset_active_record_connection
    return if ActiveRecord::Base.connected?
    ActiveRecord::Base.establish_connection(adapter: "sqlite3",
                                            database: ":memory:")
  end

  def self.init_active_record
    # remove db tree if present so we can start fresh
    root_path = Pathname(__FILE__).dirname.join('..', '..').expand_path
    db_path = root_path.join("db")
    db_path.rmtree if db_path.exist?

    # use generator to create the migration
    require 'rails/generators'
    require 'generators/flipper/active_record_generator'
    require 'generators/flipper/active_record_v2_generator'
    Rails::Generators.invoke "flipper:active_record"
    Rails::Generators.invoke "flipper:active_record_v2"

    # require migration and run it so we have the key values table
    db_path.join("migrate").children.each do |migration_path|
      require migration_path.to_s
    end

    # Turn off migration logging for specs
    ActiveRecord::Migration.verbose = false

    reset_active_record_connection
    ACTIVE_RECORD_TABLES.each do |table_name|
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table_name}")
    end

    CreateFlipperTables.up
    CreateFlipperV2Tables.up
  end

  def self.reset_active_record
    ACTIVE_RECORD_TABLES.each do |table_name|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table_name}")
    end
  end

  def self.pstore
    @pstore ||= FlipperRoot.join("tmp").tap(&:mkpath).join("flipper.pstore")
  end

  def self.reset_pstore
    pstore.unlink if pstore.exist?
  end

  def self.reset
    reset_active_record
    reset_pstore
    reset_redis
    reset_mongo
    reset_dalli
  end
end

DataStores.init_active_record
