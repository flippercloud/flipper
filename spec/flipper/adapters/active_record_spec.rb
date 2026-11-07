SpecHelpers.silence { require 'flipper/adapters/active_record' }
require 'active_record/connection_adapters/sqlite3_adapter'
require 'timeout'

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

        describe 'atomic snapshot installation' do
          let(:state_class) { Flipper::Adapters::ActiveRecord::SyncState }

          it 'installs revision zero when the state is unknown' do
            expect(subject.apply_snapshot(snapshot_with(version: 0, enabled: true))).to eq(:applied)
            expect(Flipper.new(subject)[:search]).to be_enabled
            expect(state_class.first.version).to eq(0)
          end

          it 'rejects older data across adapter instances' do
            subject.apply_snapshot(snapshot_with(version: 20, enabled: true))
            another = described_class.new

            expect(another.apply_snapshot(snapshot_with(version: 10, enabled: false))).to eq(:stale)
            expect(Flipper.new(another)[:search]).to be_enabled
            expect(state_class.first.version).to eq(20)
          end

          it 'reconciles equal revisions after an ordinary local mutation' do
            snapshot = snapshot_with(version: 20, enabled: true)
            subject.apply_snapshot(snapshot)
            Flipper.new(subject)[:search].disable

            expect(subject.apply_snapshot(snapshot)).to eq(:applied)
            expect(Flipper.new(subject)[:search]).to be_enabled
            expect(state_class.first.version).to eq(20)
          end

          it 'avoids gate writes for an identical snapshot' do
            snapshot = snapshot_with(version: 20, enabled: true)
            subject.apply_snapshot(snapshot)
            expect(subject).not_to receive(:enable)
            expect(subject).not_to receive(:disable)
            expect(subject).not_to receive(:add)
            expect(subject).not_to receive(:remove)

            expect(subject.apply_snapshot(snapshot)).to eq(:unchanged)
          end

          it 'installs a newer revision and advances its floor' do
            subject.apply_snapshot(snapshot_with(version: 20, enabled: true))

            expect(subject.apply_snapshot(snapshot_with(version: 30, enabled: false))).to eq(:applied)
            expect(Flipper.new(subject)[:search]).not_to be_enabled
            expect(state_class.first.version).to eq(30)
          end

          it 'rolls back every feature write and the revision when an installation fails' do
            subject.apply_snapshot(snapshot_with(version: 20, enabled: false))
            before = subject.get_all
            features = snapshot_with(version: 30, enabled: true).features
            features['other'] = features.fetch('search').dup
            allow(subject).to receive(:enable).and_wrap_original do |original, feature, *args|
              result = original.call(feature, *args)
              raise 'interrupted installation' if feature.key == 'other'
              result
            end

            expect do
              subject.apply_snapshot(Flipper::Snapshot.new(features: features, version: 30))
            end.to raise_error('interrupted installation')

            expect(subject.get_all).to eq(before)
            expect(state_class.first.version).to eq(20)
          end

          it 'keeps explicit imports unconditional and clears the previous floor' do
            subject.apply_snapshot(snapshot_with(version: 20, enabled: true))
            replacement = Flipper::Adapters::Memory.new(snapshot_with(version: nil, enabled: false).features)

            expect(subject.import(replacement)).to eq(true)
            expect(Flipper.new(subject)[:search]).not_to be_enabled
            expect(state_class.first.version).to be_nil
            expect(subject.apply_snapshot(snapshot_with(version: 10, enabled: true))).to eq(:applied)
          end

          it 'rejects versioned installation in an ambient transaction without changing data' do
            subject.apply_snapshot(snapshot_with(version: 20, enabled: true))
            ActiveRecord::Base.transaction do
              subject.get_all # Establish an ambient database snapshot before installation.
              expect do
                subject.apply_snapshot(snapshot_with(version: 30, enabled: false))
              end.to raise_error(ArgumentError, /transaction/)
            end

            expect(Flipper.new(subject)[:search]).to be_enabled
            expect(state_class.first.version).to eq(20)
          end

          it 'keeps unversioned import part of the callers transaction' do
            subject.apply_snapshot(snapshot_with(version: 20, enabled: true))
            replacement = Flipper::Adapters::Memory.new(snapshot_with(version: nil, enabled: false).features)
            ActiveRecord::Base.transaction do
              subject.import(replacement)
              expect(Flipper.new(subject)[:search]).not_to be_enabled
              raise ActiveRecord::Rollback
            end

            expect(Flipper.new(subject)[:search]).to be_enabled
            expect(state_class.first.version).to eq(20)
          end

          it 'does not advertise atomic installation when sync state storage is missing' do
            silence { ActiveRecord::Base.connection.drop_table(:flipper_sync_states) }
            fresh = described_class.new

            expect(fresh.supports?(:atomic_snapshot_install)).to eq(false)
            expect { fresh.apply_snapshot(snapshot_with(version: 20, enabled: true)) }.to raise_error(NotImplementedError)
            expect(fresh.import(Flipper::Adapters::Memory.new)).to eq(true)
          end

          it 'does not advertise atomic installation across different connection pools' do
            separate_model = Class.new(ActiveRecord::Base) { self.abstract_class = true }
            stub_const('SeparateSyncRecord', separate_model)
            separate_model.establish_connection(config)
            separate_state = Class.new(separate_model) { self.table_name = 'flipper_sync_states' }
            stub_const('SeparateSyncState', separate_state)
            adapter = described_class.new(sync_state_class: separate_state)

            expect(adapter.supports?(:atomic_snapshot_install)).to eq(false)
          ensure
            separate_model&.connection_pool&.disconnect!
          end

          [false, true].each do |cold_start|
            it "serializes independent connections (cold start: #{cold_start})" do
              skip 'SQLite in-memory databases are separate per connection' if config['adapter'] == 'sqlite3'

              subject.apply_snapshot(snapshot_with(version: 5, enabled: false)) if !cold_start
              newer = described_class.new
              older = described_class.new
              locked = Queue.new
              attempted = Queue.new
              release = Queue.new
              connections = Queue.new
              allow(newer).to receive(:enable).and_wrap_original do |original, *args|
                result = original.call(*args)
                locked << true
                release.pop
                result
              end
              allow(older).to receive(:lock_sync_state).and_wrap_original do |original|
                attempted << true
                original.call
              end

              newer_writer = Thread.new do
                ActiveRecord::Base.connection_pool.with_connection do |connection|
                  connections << connection.object_id
                  newer.apply_snapshot(snapshot_with(version: 20, enabled: true))
                end
              end
              newer_writer.report_on_exception = false
              Timeout.timeout(5) { locked.pop }
              older_writer = Thread.new do
                ActiveRecord::Base.connection_pool.with_connection do |connection|
                  connections << connection.object_id
                  older.apply_snapshot(snapshot_with(version: 10, enabled: false))
                end
              end
              older_writer.report_on_exception = false
              Timeout.timeout(5) { attempted.pop }
              expected_before = cold_start ? {} : snapshot_with(version: 5, enabled: false).features
              expect(subject.get_all).to eq(expected_before)
              release << true

              expect(Timeout.timeout(5) { newer_writer.value }).to eq(:applied)
              expect(Timeout.timeout(5) { older_writer.value }).to eq(:stale)
              expect([connections.pop, connections.pop].uniq.size).to eq(2)
              expect(Flipper.new(subject)[:search]).to be_enabled
              expect(state_class.first.version).to eq(20)
            ensure
              release << true if release
              [newer_writer, older_writer].compact.each do |writer|
                writer.kill if writer.alive?
                writer.join(1)
              end
            end
          end
        end

        it "ignores gate rows with unknown keys" do
          flipper = Flipper.new(subject)
          flipper.enable_actor(:foo, Flipper::Actor.new("User;1"))

          Flipper::Adapters::ActiveRecord::Gate.create!(
            feature_key: "foo",
            key: "not_a_real_gate",
            value: "junk",
          )

          expected = subject.default_config.merge(actors: Set["User;1"])
          feature = flipper[:foo]
          expect(subject.get(feature)).to eq(expected)
          expect(subject.get_multi([feature])).to eq("foo" => expected)
          expect(subject.get_all).to eq("foo" => expected)
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

        it "warns once if the gates value column is not text" do
          allow(Flipper::Adapters::ActiveRecord::Gate).
            to receive(:column_for_attribute).
            with(:value).
            and_return(double(type: :string))

          output = capture_output do
            2.times { subject.features }
          end

          expect(output.scan("Your database needs to be migrated").size).to eq(1)
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
                gate_class: gate_class,
                sync_state_class: sync_state_class
              )
            end

            let(:sync_state_class) do
              klass = Class.new(abstract_class) do
                self.table_name = 'flipper_sync_states'
              end
              stub_const('TestSyncState', klass)
              klass
            end

            it 'installs snapshots on the writer connection while the caller uses the reading role' do
              abstract_class.connected_to(role: :reading) do
                expect(adapter_with_roles.supports?(:atomic_snapshot_install)).to eq(true)
                snapshot = snapshot_with(version: 20, enabled: true)
                expect(adapter_with_roles.apply_snapshot(snapshot)).to eq(:applied)
                expect(adapter_with_roles.get_all).to eq(snapshot.features)
                expect(sync_state_class.first.version).to eq(20)
                expect(abstract_class.current_role).to eq(:reading)
              end
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

  def snapshot_with(version:, enabled:)
    features = { 'search' => described_class.default_config.merge(boolean: enabled ? 'true' : nil) }
    Flipper::Snapshot.new(features: features, version: version)
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
