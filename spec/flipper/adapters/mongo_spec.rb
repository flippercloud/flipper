require 'helper'
require 'flipper/adapters/mongo'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Mongo do
  subject { described_class.new(DataStores.mongo) }

  before do
    DataStores.reset_mongo
  end

  it_should_behave_like 'a flipper adapter'
end
