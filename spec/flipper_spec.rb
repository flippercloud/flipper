require 'helper'

describe Flipper do
  describe ".configuration" do
    it "defaults to an instance of configuration" do
      Flipper.configuration.should be_instance_of(Flipper::Configuration)
    end
  end

  describe ".configure" do
    before do
      @original_adapter = Flipper.configuration.adapter
    end

    after do
      Flipper.configuration.adapter = @original_adapter
    end

    it "yields configuration to block" do
      adapter = double('Adapter')
      Flipper.configure do |config|
        config.adapter = adapter
      end
      Flipper.configuration.adapter.should eq(adapter)
    end
  end
end
