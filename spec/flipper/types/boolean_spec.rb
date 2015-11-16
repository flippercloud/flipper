require 'helper'
require 'flipper/types/boolean'

RSpec.describe Flipper::Types::Boolean do
  it "defaults value to true" do
    boolean = Flipper::Types::Boolean.new
    expect(boolean.value).to be(true)
  end

  it "allows overriding default value" do
    boolean = Flipper::Types::Boolean.new(false)
    expect(boolean.value).to be(false)
  end

  it "returns true for nil value" do
    boolean = Flipper::Types::Boolean.new(nil)
    expect(boolean.value).to be(true)
  end

  it "typecasts value" do
    boolean = Flipper::Types::Boolean.new(1)
    expect(boolean.value).to be(true)
  end
end
