SpecHelpers.silence { require 'flipper/adapters/active_record' }

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false
ActiveRecord::Tasks::DatabaseTasks.root = File.dirname(__FILE__)

RSpec.describe Flipper::Adapters::ActiveRecord do
  subject { described_class.new }

  before(:all) do
    # Eval migration template so we can run migration against each database
    template_path = File.join(File.dirname(__FILE__), '../../../lib/generators/flipper/templates/migration.erb')
    migration = ERB.new(File.read(template_path))
    migration_version = "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
    eval migration.result_with_hash(migration_version: migration_version) # defines CreateFlipperTables
  end

  [
    {
      "adapter" => "sqlite3",
      "database" => ":memory:"
    },

    {
      "adapter" => "mysql2",
      "encoding" => "utf8mb4",
      "host" => ENV["MYSQL_HOST"],
      "username" => ENV["MYSQL_USER"] || "root",
      "password" => ENV["MYSQL_PASSWORD"] || "",
      "database" => ENV["MYSQL_DATABASE"] || "flipper_test",
      "port" => ENV["DB_PORT"] || 3306
    },

    {
      "adapter" => "postgresql",
      "encoding" => "unicode",
      "host" => "127.0.0.1",
      "username" => ENV["POSTGRES_USER"] || "",
      "password" => ENV["POSTGRES_PASSWORD"] || "",
      "database" => ENV["POSTGRES_DATABASE"] || "flipper_test",
    }
  ].each do |config|
    context "with #{config['adapter']}" do
      context "with tables created" do
        before(:all) do
          skip_on_error(ActiveRecord::ConnectionNotEstablished, "#{config['adapter']} not available") do
            silence do
              ActiveRecord::Tasks::DatabaseTasks.create(config)
            end
          end

          Flipper.configuration = nil
        end

        before(:each) do
          silence do
            ActiveRecord::Tasks::DatabaseTasks.purge(config)
            CreateFlipperTables.migrate(:up)
          end
        end

        after(:all) do
          silence { ActiveRecord::Tasks::DatabaseTasks.drop(config) } unless $skip
        end

        it_should_behave_like 'a flipper adapter'

        it "should load actor ids fine" do
          flipper.enable_percentage_of_time(:foo, 1)

          Flipper::Adapters::ActiveRecord::Gate.create!(
            feature_key: "foo",
            key: "actors",
            value: "Organization;4",
          )

          flipper = Flipper.new(subject)
          flipper.preload([:foo])
        end

        it 'should not poison wrapping transactions' do
          flipper = Flipper.new(subject)

          actor = Struct.new(:flipper_id).new('flipper-id-123')
          flipper.enable_actor(:foo, actor)

          ActiveRecord::Base.transaction do
            flipper.enable_actor(:foo, actor)
            # any read on the next line is fine, just need to ensure that
            # poisoned transaction isn't raised
            expect(Flipper::Adapters::ActiveRecord::Gate.count).to eq(1)
          end
        end

        context "ActiveRecord connection_pool" do
          before do
            ActiveRecord::Base.connection_handler.clear_active_connections!
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

        context 'requiring "flipper-active_record"' do
          before do
            Flipper.configuration = nil
            Flipper.instance = nil

            silence { load 'flipper/adapters/active_record.rb' }
          end

          it 'configures itself' do
            expect(Flipper.adapter.adapter).to be_a(Flipper::Adapters::ActiveRecord)
          end
        end
      end

      context "without tables created" do
        before(:all) do
          skip_on_error(ActiveRecord::ConnectionNotEstablished, "#{config['adapter']} not available") do
            silence do
              ActiveRecord::Tasks::DatabaseTasks.create(config)
            end
          end

          Flipper.configuration = nil
        end

        before(:each) do
          ActiveRecord::Base.establish_connection(config)
        end

        after(:each) do
          ActiveRecord::Base.connection.close
        end

        after(:all) do
          silence { ActiveRecord::Tasks::DatabaseTasks.drop(config) } unless $skip
        end

        it "does not raise an error" do
          Flipper.configuration = nil
          Flipper.instance = nil

          silence do
            expect {
              load 'flipper/adapters/active_record.rb'
              Flipper::Adapters::ActiveRecord.new
            }.not_to raise_error
          end
        end
      end
    end
  end
end
