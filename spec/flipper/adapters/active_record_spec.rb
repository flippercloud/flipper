require 'flipper/adapters/active_record'
require 'active_support/core_ext/kernel'

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

  it "works when table doesn't exist" do
    ActiveRecord::Base.connection.execute("DROP table IF EXISTS `flipper_gates`")

    Flipper.configuration = nil
    Flipper.instance = nil

    silence_warnings { load 'flipper/adapters/active_record.rb' }
    expect { Flipper::Adapters::ActiveRecord.new }.not_to raise_error
  end

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

  context "ActiveRecord connection_pool" do
    before do
      ActiveRecord::Base.clear_active_connections!
    end

    context "#features" do
      it "does not hold onto connections" do
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
        subject.features
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
      end

      it "does not release previously held connection" do
        ActiveRecord::Base.connection # establish a new connection
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
        subject.features
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
      end
    end

    context "#get_all" do
      it "does not hold onto connections" do
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
        subject.get_all
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
      end

      it "does not release previously held connection" do
        ActiveRecord::Base.connection # establish a new connection
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
        subject.get_all
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
      end
    end

    context "#add / #remove / #clear" do
      let(:feature) { Flipper::Feature.new(:search, subject) }

      it "does not hold onto connections" do
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
        subject.add(feature)
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
        subject.remove(feature)
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
        subject.clear(feature)
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
      end

      it "does not release previously held connection" do
        ActiveRecord::Base.connection # establish a new connection
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
        subject.add(feature)
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
        subject.remove(feature)
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
        subject.clear(feature)
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
      end
    end

    context "#get_multi" do
      let(:feature) { Flipper::Feature.new(:search, subject) }

      it "does not hold onto connections" do
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
        subject.get_multi([feature])
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
      end

      it "does not release previously held connection" do
        ActiveRecord::Base.connection # establish a new connection
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
        subject.get_multi([feature])
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
      end
    end

    context "#enable/#disable boolean" do
      let(:feature) { Flipper::Feature.new(:search, subject) }
      let(:gate) { feature.gate(:boolean)}

      it "does not hold onto connections" do
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
        subject.enable(feature, gate, gate.wrap(true))
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
        subject.disable(feature, gate, gate.wrap(false))
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
      end

      it "does not release previously held connection" do
        ActiveRecord::Base.connection # establish a new connection
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
        subject.enable(feature, gate, gate.wrap(true))
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
        subject.disable(feature, gate, gate.wrap(false))
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
      end
    end

    context "#enable/#disable set" do
      let(:feature) { Flipper::Feature.new(:search, subject) }
      let(:gate) { feature.gate(:group) }

      it "does not hold onto connections" do
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
        subject.enable(feature, gate, gate.wrap(:admin))
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
        subject.disable(feature, gate, gate.wrap(:admin))
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
      end

      it "does not release previously held connection" do
        ActiveRecord::Base.connection # establish a new connection
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
        subject.enable(feature, gate, gate.wrap(:admin))
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
        subject.disable(feature, gate, gate.wrap(:admin))
        expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
      end
    end
  end
end
