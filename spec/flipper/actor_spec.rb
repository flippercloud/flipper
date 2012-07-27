require 'helper'
require 'flipper/actor'

describe Flipper::Actor do
  subject {
    Flipper::Actor.new(2)
  }

  it "initializes with identifier" do
    actor = Flipper::Actor.new(2)
    actor.should be_instance_of(Flipper::Actor)
  end

  it "has identifier" do
    actor = Flipper::Actor.new(2)
    actor.identifier.should eq(2)
  end
end
