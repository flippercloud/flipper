require 'sequel'

Sequel::Model.db = Sequel.sqlite(':memory:')
Sequel.extension :migration, :core_extensions

require 'flipper/adapters/sequel'
require 'generators/flipper/templates/sequel_migration'

RSpec.describe Flipper::Adapters::Sequel do
  subject do
    described_class.new(feature_class: feature_class,
                        gate_class: gate_class)
  end

  let(:feature_class) { Flipper::Adapters::Sequel::Feature }
  let(:gate_class) { Flipper::Adapters::Sequel::Gate }
  let(:kv_integer_class) { Flipper::Adapters::Sequel::KvInteger }

  before(:each) do
    CreateFlipperTablesSequel.new(Sequel::Model.db).up
    feature_class.dataset = feature_class.dataset
    gate_class.dataset = gate_class.dataset
    kv_integer_class.dataset = kv_integer_class.dataset
  end

  after(:each) do
    CreateFlipperTablesSequel.new(Sequel::Model.db).down
  end

  it_should_behave_like 'a flipper adapter'

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

    it 'recovers from a transient DatabaseError on the table presence check' do
      fresh = described_class.new(feature_class: feature_class, gate_class: gate_class)
      kv_class = fresh.instance_variable_get(:@kv_integer_class)

      call_count = 0
      allow(kv_class.db).to receive(:table_exists?).and_wrap_original do |original, *args|
        call_count += 1
        raise ::Sequel::DatabaseError, 'transient blip' if call_count == 1
        original.call(*args)
      end

      expect(fresh.read_integer(:sync_version)).to be_nil
      expect(fresh.set_integer_if_greater(:sync_version, 100)).to eq(true)
      expect(fresh.read_integer(:sync_version)).to eq(100)
    end
  end

  context 'requiring "flipper-sequel"' do
    before do
      Flipper.configuration = nil
      Flipper.instance = nil

      silence { load 'flipper/adapters/sequel.rb' }
    end

    it 'configures itself' do
      expect(Flipper.adapter.adapter).to be_a(Flipper::Adapters::Sequel)
    end

    it "defines #flipper_id on Sequel::Model" do
      expect(Sequel::Model.ancestors).to include(Flipper::Identifier)
    end

    it "defines #flipper_properties on Sequel::Model" do
      expect(Sequel::Model.ancestors).to include(Flipper::Model::Sequel)
    end
  end
end
