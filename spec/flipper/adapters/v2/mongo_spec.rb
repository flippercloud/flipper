require 'helper'
require 'flipper/adapters/v2/mongo'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::Mongo do
  subject { described_class.new(DataStores.mongo) }

  before do
    DataStores.reset_mongo
  end

  it_should_behave_like 'a v2 flipper adapter'
end
