require 'helper'
require 'flipper/types/actor'

describe Flipper::Types::Actor do
  subject {
    Flipper::Types::Actor.new(2)
  }

  it "initializes with identifier" do
    actor = Flipper::Types::Actor.new(2)
    actor.should be_instance_of(Flipper::Types::Actor)
  end

  it "has identifier" do
    actor = Flipper::Types::Actor.new(2)
    actor.identifier.should eq(2)
  end
end
