require 'helper'
require 'flipper/adapters/mongo'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Mongo do
  let(:collection) { Mongo::MongoClient.new('localhost', ENV["BOXEN_MONGODB_PORT"]).db('testing')['testing'] }

  subject { described_class.new(collection) }

  before do
    collection.remove
  end

  it_should_behave_like 'a flipper adapter'
end
