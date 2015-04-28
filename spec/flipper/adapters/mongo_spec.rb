require 'helper'
require 'flipper/adapters/mongo'
require 'flipper/spec/shared_adapter_specs'

Mongo::Logger.logger.level = Logger::INFO

describe Flipper::Adapters::Mongo do
  let(:collection) {
    Mongo::Client.new(["127.0.0.1:#{ENV["BOXEN_MONGODB_PORT"] || 27017}"], :database => 'testing')['testing']
  }

  subject { described_class.new(collection) }

  before do
    begin
      collection.drop
    rescue Mongo::Error::OperationFailure
    end
    collection.create
  end

  it_should_behave_like 'a flipper adapter'
end
