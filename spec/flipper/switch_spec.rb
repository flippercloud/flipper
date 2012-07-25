require 'helper'
require 'flipper/switch'

describe Flipper::Switch do
  it "initializes with nothing" do
    switch = Flipper::Switch.new
    switch.should be_instance_of(Flipper::Switch)
  end
end
