require 'helper'
require 'flipper/types/boolean'

describe Flipper::Types::Boolean do
  it "initializes with nothing" do
    switch = Flipper::Types::Boolean.new
    switch.should be_instance_of(Flipper::Types::Boolean)
  end
end
