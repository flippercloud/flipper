require 'helper'
require 'flipper/adapters/v2/mongo'
require 'flipper/spec/shared_adapter_specs'

Mongo::Logger.logger.level = Logger::INFO

RSpec.describe Flipper::Adapters::V2::Mongo do
  let(:host) { ENV["BOXEN_MONGODB_HOST"] || '127.0.0.1' }
  let(:port) { ENV["BOXEN_MONGODB_PORT"] || 27017 }

  let(:collection) {
    Mongo::Client.new(["#{host}:#{port}"], :server_selection_timeout => 1, :database => 'testing')['testing']
  }

  subject { described_class.new(collection) }

  before do
    begin
      collection.drop
    rescue Mongo::Error::OperationFailure
    end
    collection.create
  end

  it_should_behave_like 'a v2 flipper adapter'
end
