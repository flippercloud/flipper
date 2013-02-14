require 'helper'
require 'flipper/types/boolean'

describe Flipper::Types::Boolean do
  it "defaults value to true" do
    boolean = Flipper::Types::Boolean.new
    boolean.value.should be(true)
  end

  it "allows overriding default value" do
    boolean = Flipper::Types::Boolean.new(false)
    boolean.value.should be(false)
  end

  it "returns true for nil value" do
    boolean = Flipper::Types::Boolean.new(nil)
    boolean.value.should be(true)
  end
end
