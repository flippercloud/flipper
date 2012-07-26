require 'helper'
require 'flipper/boolean'

describe Flipper::Boolean do
  it "initializes with nothing" do
    switch = Flipper::Boolean.new
    switch.should be_instance_of(Flipper::Boolean)
  end
end
