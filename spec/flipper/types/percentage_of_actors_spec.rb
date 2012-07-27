require 'helper'
require 'flipper/types/percentage_of_actors'

describe Flipper::Types::PercentageOfActors do
  subject {
    Flipper::Types::PercentageOfActors.new(19)
  }

  it "initializes with value" do
    percentage = Flipper::Types::PercentageOfActors.new(12)
    percentage.should be_instance_of(Flipper::Types::PercentageOfActors)
  end

  it "converts string values to integers when initializing" do
    percentage = Flipper::Types::PercentageOfActors.new('15')
    percentage.value.should eq(15)
  end

  it "has a value" do
    subject.value.should eq(19)
  end
end
