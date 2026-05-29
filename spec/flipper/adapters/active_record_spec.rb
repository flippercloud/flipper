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

        describe 'read_integer / set_integer_if_greater' do
          it 'returns nil for unknown keys' do
            expect(subject.read_integer(:sync_version)).to be_nil
          end

          it 'sets a new value when none exists' do
            expect(subject.set_integer_if_greater(:sync_version, 100)).to eq(true)
            expect(subject.read_integer(:sync_version)).to eq(100)
          end

          it 'rejects a lower value' do
            subject.set_integer_if_greater(:sync_version, 100)
            expect(subject.set_integer_if_greater(:sync_version, 99)).to eq(false)
            expect(subject.read_integer(:sync_version)).to eq(100)
          end

          it 'rejects an equal value' do
            subject.set_integer_if_greater(:sync_version, 100)
            expect(subject.set_integer_if_greater(:sync_version, 100)).to eq(false)
            expect(subject.read_integer(:sync_version)).to eq(100)
          end

          it 'accepts a strictly greater value' do
            subject.set_integer_if_greater(:sync_version, 100)
            expect(subject.set_integer_if_greater(:sync_version, 200)).to eq(true)
            expect(subject.read_integer(:sync_version)).to eq(200)
          end

          it 'tracks separate keys independently' do
            subject.set_integer_if_greater(:foo, 100)
            subject.set_integer_if_greater(:bar, 50)
            expect(subject.read_integer(:foo)).to eq(100)
            expect(subject.read_integer(:bar)).to eq(50)
          end

          context 'when flipper_kv_integers table is missing' do
            before do
              silence { ActiveRecord::Base.connection.drop_table(:flipper_kv_integers) }
            end

            it 'read_integer returns nil' do
              fresh = described_class.new
              expect(fresh.read_integer(:sync_version)).to be_nil
            end

            it 'set_integer_if_greater returns false' do
              fresh = described_class.new
              expect(fresh.set_integer_if_greater(:sync_version, 100)).to eq(false)
            end
          end

          it 'recovers from a transient StatementInvalid on the table presence check' do
            fresh = described_class.new
            kv_class = fresh.instance_variable_get(:@kv_integer_class)

            call_count = 0
            allow(kv_class).to receive(:table_exists?).and_wrap_original do |original, *args|
              call_count += 1
              raise ::ActiveRecord::StatementInvalid, 'transient blip' if call_count == 1
              original.call(*args)
            end

            expect(fresh.read_integer(:sync_version)).to be_nil
            expect(fresh.set_integer_if_greater(:sync_version, 100)).to eq(true)
            expect(fresh.read_integer(:sync_version)).to eq(100)
          end
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
            clear_active_connections!
          end

          context "#features" do
            it "does not hold onto connections" do
              expect(active_connections?).to be(false)
              subject.features
              expect(active_connections?).to be(false)
            end

            it "does not release previously held connection" do
              ActiveRecord::Base.connection # establish a new connection
              expect(active_connections?).to be(true)
              subject.features
              expect(active_connections?).to be(true)
            end
          end

          context "#get_all" do
            it "does not hold onto connections" do
              expect(active_connections?).to be(false)
              subject.get_all
              expect(active_connections?).to be(false)
            end

            it "does not release previously held connection" do
              ActiveRecord::Base.connection # establish a new connection
              expect(active_connections?).to be(true)
              subject.get_all
              expect(active_connections?).to be(true)
            end
          end

          context "#add / #remove / #clear" do
            let(:feature) { Flipper::Feature.new(:search, subject) }

            it "does not hold onto connections" do
              expect(active_connections?).to be(false)
              subject.add(feature)
              expect(active_connections?).to be(false)
              subject.remove(feature)
              expect(active_connections?).to be(false)
              subject.clear(feature)
              expect(active_connections?).to be(false)
            end

            it "does not release previously held connection" do
              ActiveRecord::Base.connection # establish a new connection
              expect(active_connections?).to be(true)
              subject.add(feature)
              expect(active_connections?).to be(true)
              subject.remove(feature)
              expect(active_connections?).to be(true)
              subject.clear(feature)
              expect(active_connections?).to be(true)
            end
          end

          context "#get_multi" do
            let(:feature) { Flipper::Feature.new(:search, subject) }

            it "does not hold onto connections" do
              expect(active_connections?).to be(false)
              subject.get_multi([feature])
              expect(active_connections?).to be(false)
            end

            it "does not release previously held connection" do
              ActiveRecord::Base.connection # establish a new connection
              expect(active_connections?).to be(true)
              subject.get_multi([feature])
              expect(active_connections?).to be(true)
            end
          end

          context "#enable/#disable boolean" do
            let(:feature) { Flipper::Feature.new(:search, subject) }
            let(:gate) { feature.gate(:boolean)}

            it "does not hold onto connections" do
              expect(active_connections?).to be(false)
              subject.enable(feature, gate, gate.wrap(true))
              expect(active_connections?).to be(false)
              subject.disable(feature, gate, gate.wrap(false))
              expect(active_connections?).to be(false)
            end

            it "does not release previously held connection" do
              ActiveRecord::Base.connection # establish a new connection
              expect(active_connections?).to be(true)
              subject.enable(feature, gate, gate.wrap(true))
              expect(active_connections?).to be(true)
              subject.disable(feature, gate, gate.wrap(false))
              expect(active_connections?).to be(true)
            end
          end

          context "#enable/#disable set" do
            let(:feature) { Flipper::Feature.new(:search, subject) }
            let(:gate) { feature.gate(:group) }

            it "does not hold onto connections" do
              expect(active_connections?).to be(false)
              subject.enable(feature, gate, gate.wrap(:admin))
              expect(active_connections?).to be(false)
              subject.disable(feature, gate, gate.wrap(:admin))
              expect(active_connections?).to be(false)
            end

            it "does not release previously held connection" do
              ActiveRecord::Base.connection # establish a new connection
              expect(active_connections?).to be(true)
              subject.enable(feature, gate, gate.wrap(:admin))
              expect(active_connections?).to be(true)
              subject.disable(feature, gate, gate.wrap(:admin))
              expect(active_connections?).to be(true)
            end
          end
        end

        if ActiveRecord.version >= Gem::Version.new('7.1')
          context 'with read/write roles' do
            before do
              skip "connected_to with roles is not supported on #{config['adapter']}" if config["adapter"] == "sqlite3"
            end

            let(:abstract_class) do
              # Create a named abstract class (Rails requires names for connects_to)
              klass = Class.new(ActiveRecord::Base) do
                self.abstract_class = true
              end
              stub_const('TestApplicationRecord', klass)

              # Now configure connects_to with the same database for both roles
              # In production, these would be different (primary/replica)
              klass.connects_to database: {
                writing: config,
                reading: config
              }

              klass
            end

            after do
              # Disconnect role-based connections to avoid interfering with database cleanup
              clear_all_connections!
            end

            let(:feature_class) do
              klass = Class.new(abstract_class) do
                self.table_name = 'flipper_features'
                validates :key, presence: true
              end
              stub_const('TestFeature', klass)
              klass
            end

            let(:gate_class) do
              klass = Class.new(abstract_class) do
                self.table_name = 'flipper_gates'
              end
              stub_const('TestGate', klass)
              klass
            end

            let(:adapter_with_roles) do
              described_class.new(
                feature_class: feature_class,
                gate_class: gate_class
              )
            end

            it 'can perform write operations when forced to reading role' do
              abstract_class.connected_to(role: :reading) do
                flipper = Flipper.new(adapter_with_roles)

                feature = flipper[:test_feature]
                expect { feature.enable }.not_to raise_error
                expect(feature.enabled?).to be(true)
                expect { feature.disable }.not_to raise_error
                expect(feature.enabled?).to be(false)

                feature = flipper[:actor_test]
                actor = Struct.new(:flipper_id).new(123)
                expect { feature.enable_actor(actor) }.not_to raise_error
                expect(feature.enabled?(actor)).to be(true)
                expect { feature.disable_actor(actor) }.not_to raise_error
                expect(feature.enabled?(actor)).to be(false)

                feature = flipper[:gate_test]
                expect { feature.enable_percentage_of_time(50) }.not_to raise_error
                expect { feature.disable_percentage_of_time }.not_to raise_error
                feature.enable
                expect { feature.remove }.not_to raise_error

                feature = flipper[:expression_test]
                expression = Flipper.property(:plan).eq("premium")
                expect { feature.enable_expression(expression) }.not_to raise_error
                expect(feature.expression).to eq(expression)
                expect { feature.disable_expression }.not_to raise_error
                expect(feature.expression).to be_nil
              end
            end

            it 'does not hold onto connections during write operations' do
              clear_active_connections!

              abstract_class.connected_to(role: :reading) do
                flipper = Flipper.new(adapter_with_roles)
                feature = flipper[:connection_test]

                feature.enable
                expect(active_connections?).to be(false)
              end
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

  def active_connections?
    method = ActiveRecord::Base.connection_handler.method(:active_connections?)
    method.arity == 0 ? method.call : method.call(:all)
  end

  def clear_active_connections!
    method = ActiveRecord::Base.connection_handler.method(:clear_active_connections!)
    method.arity == 0 ? method.call : method.call(:all)
  end

  def clear_all_connections!
    method = ActiveRecord::Base.connection_handler.method(:clear_all_connections!)
    method.arity == 0 ? method.call : method.call(:all)
  end
end
