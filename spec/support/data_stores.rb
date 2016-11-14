# Require the migrations so we can use them
require 'active_record'
require 'redis'
require 'mongo'
require 'pstore'
require 'generators/flipper/templates/migration'
require 'generators/flipper/templates/v2_migration'

Mongo::Logger.logger.level = Logger::INFO
ActiveRecord::Migration.verbose = false

module DataStores
  def self.redis
    @redis ||= Redis.new
  end

  def self.reset_redis
    redis.flushdb
  end

  def self.mongo
    @mongo ||= Mongo::Client.new(["127.0.0.1:27017"], :server_selection_timeout => 1, :database => 'testing')['testing']
  end

  def self.reset_mongo
    mongo.delete_many
  end

  def self.dalli
    @dalli ||= Dalli::Client.new('localhost:11211')
  end

  def self.reset_dalli
    dalli.flush
  end

  def self.reset_active_record_connection
    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.establish_connection({
        adapter: "sqlite3",
        database: ":memory:",
      })
    end
  end

  def self.reset_active_record
    reset_active_record_connection
    tables = Set.new(ActiveRecord::Base.connection.tables)

    if tables.include?("flipper_features")
      ActiveRecord::Base.connection.execute("DROP TABLE flipper_features")
    end

    if tables.include?("flipper_gates")
      ActiveRecord::Base.connection.execute("DROP TABLE flipper_gates")
    end

    if tables.include?("flipper_keys")
      ActiveRecord::Base.connection.execute("DROP TABLE flipper_keys")
    end

    CreateFlipperTables.up
    CreateFlipperV2Tables.up
  end

  def self.pstore
    @pstore ||= FlipperRoot.join("tmp").tap { |d| d.mkpath }.join("flipper.pstore")
  end

  def self.reset_pstore
    if pstore.exist?
      pstore.unlink
    end
  end

  def self.reset
    reset_active_record
    reset_pstore
    reset_redis
    reset_mongo
    reset_dalli
  end
end
