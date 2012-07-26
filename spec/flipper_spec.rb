require 'helper'

describe Flipper do
  before do
    @original_adapter = Flipper.configuration.adapter
  end

  after do
    Flipper.configuration.adapter = @original_adapter
  end

  it "defaults configuration to new instance" do
    Flipper.configuration.should be_instance_of(Flipper::Configuration)
  end

  it "has configuration accessor" do
    new_configuration = Flipper::Configuration.new
    Flipper.configuration = new_configuration
    Flipper.configuration.should eq(new_configuration)
  end

  describe ".configure" do
    it "yields configuration to block" do
      adapter = double('Adapter')
      Flipper.configure do |config|
        config.adapter = adapter
      end
      Flipper.configuration.adapter.should eq(adapter)
    end
  end
end
