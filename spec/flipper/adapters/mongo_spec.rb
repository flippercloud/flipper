require 'helper'
require 'flipper/adapters/mongo'
require 'flipper/spec/shared_adapter_specs'

Mongo::Logger.logger.level = Logger::INFO

RSpec.describe Flipper::Adapters::Mongo do
  subject { described_class.new(collection) }

  let(:host) { ENV['MONGODB_HOST'] || '127.0.0.1' }
  let(:port) { ENV['MONGODB_PORT'] || 27017 }

  let(:client) do
    logger = Logger.new('/dev/null')
    Mongo::Client.new(["#{host}:#{port}"], server_selection_timeout: 0.01, database: 'testing', logger: logger)
  end
  let(:collection) { client['testing'] }

  before do
    begin
      collection.drop
    rescue Mongo::Error::NoServerAvailable
      ENV['CI'] ? raise : skip('Mongo not available')
    rescue Mongo::Error::OperationFailure
    end
    collection.create
  end

  it_should_behave_like 'a flipper adapter'

  it 'configures itself on load' do
    Flipper.configuration = nil
    Flipper.instance = nil

    load 'flipper-mongo.rb'

    ENV["MONGO_URL"] ||= "mongodb://127.0.0.1:27017/testing"
    expect(Flipper.adapter.adapter).to be_a(Flipper::Adapters::Mongo)
  end
end
