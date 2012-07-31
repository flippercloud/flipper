require 'helper'
require 'flipper/adapters/mongo'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Mongo do
  let(:collection) { Mongo::Connection.new.db('testing')['testing'] }
  let(:oid)        { BSON::ObjectId.new }
  let(:criteria)   { {:_id => oid} }

  subject { Flipper::Adapters::Mongo.new(collection, oid) }

  before do
    collection.remove(criteria)
  end

  def read_key(key)
    if (doc = collection.find_one(criteria))
      value = doc[key]

      if value.is_a?(::Array)
        value = value.to_set
      end

      value
    end
  end

  def write_key(key, value)
    if value.is_a?(::Set)
      value = value.to_a
    end

    options = {:upsert => true}
    updates = {'$set' => {key => value}}
    collection.update criteria, updates, options
  end

  it_should_behave_like 'a flipper adapter'

  it "can cache document in process for a number of seconds" do
    options = {:ttl => 10}
    adapter = Flipper::Adapters::Mongo.new(collection, oid, options)
    adapter.write('foo', 'bar')
    now = Time.now
    Timecop.freeze(now)

    collection.should_receive(:find_one).with(:_id => oid)
    adapter.read('foo')

    adapter.read('foo')
    adapter.read('bar')

    Timecop.travel(3)
    adapter.read('foo')

    Timecop.travel(6)
    adapter.read('foo')

    collection.should_receive(:find_one).with(:_id => oid)
    Timecop.travel(1)
    adapter.read('foo')

    Timecop.travel(4)
    adapter.read('foo')
  end
end
