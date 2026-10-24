require 'flipper/adapters/mongo'

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
    skip_on_error(Mongo::Error::NoServerAvailable, 'Mongo not available') do
      begin
        collection.drop
      rescue Mongo::Error::OperationFailure
      end
    end
    collection.create
  end

  it_should_behave_like 'a flipper adapter'
  it_should_behave_like 'an adapter that protects its feature list' do
    let(:add_reserved_name_to_list) do
      collection.find(_id: "flipper_features").update_one({ "$addToSet" => { "features" => "flipper_features" } })
    end
  end

  it 'configures itself on load' do
    Flipper.configuration = nil
    Flipper.instance = nil

    silence { load 'flipper/adapters/mongo.rb' }

    ENV["MONGO_URL"] = ENV.fetch("MONGO_URL", "mongodb://127.0.0.1:27017/testing")
    expect(Flipper.adapter.adapter).to be_a(Flipper::Adapters::Mongo)
  end
end
