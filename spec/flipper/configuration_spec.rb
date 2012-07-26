require 'helper'
require 'flipper/configuration'

describe Flipper::Configuration do
  subject { Flipper::Configuration.new }

  it "should have accessor for adapter" do
    adapter = double('Adapter')
    subject.adapter = adapter
    subject.adapter.should eq(adapter)
  end
end
