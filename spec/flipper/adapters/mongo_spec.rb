require 'helper'
require 'flipper/adapters/mongo'
require 'flipper/spec/shared_adapter_specs'

Mongo::Logger.logger.level = Logger::INFO

RSpec.describe Flipper::Adapters::Mongo do
  subject { described_class.new(collection) }

  let(:host) { ENV['MONGODB_HOST'] || '127.0.0.1' }
  let(:port) { ENV['MONGODB_PORT'] || 27017 }

  let(:client) do
    Mongo::Client.new(["#{host}:#{port}"], server_selection_timeout: 1, database: 'testing')
  end
  let(:collection) { client['testing'] }

  before do
    begin
      collection.drop
    rescue Mongo::Error::OperationFailure
    end
    collection.create
  end

  it_should_behave_like 'a flipper adapter'

  it 'configures itself on load' do
    Flipper.configuration = nil
    Flipper.instance = nil

    require 'flipper-mongo'

    ENV["MONGO_URL"] ||= "mongodb://127.0.0.1:27017/testing"
    expect(Flipper.adapter.adapter).to be_a(Flipper::Adapters::Mongo)
  end
end
