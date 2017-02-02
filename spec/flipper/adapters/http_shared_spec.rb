require 'helper'
require 'flipper/adapters/http'
require 'flipper/adapters/memory'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Http do
  context 'adapter' do
    let(:mount_path) { URI('http://localhost:8080/') }
    subject { described_class.new(mount_path) }
    let(:memory_adapter) {  Flipper::Adapters::Memory.new }
    let(:flipper_api) { Flipper.new(memory_adapter) }
    let(:app) {  Flipper::Api.app(flipper_api) }

    before(:each) do
      memory_adapter =  Flipper::Adapters::Memory.new
      flipper_api = Flipper.new(memory_adapter)
      app =  Flipper::Api.app(flipper_api)
      Thread.new { Rack::Handler::WEBrick.run(app, Port: 8080) }
      sleep(1)
      feature_class = Struct.new(:key)
      subject.features.each { |f| subject.remove(feature_class.new(f)) }
    end

    it_should_behave_like 'a flipper adapter'
  end
end
