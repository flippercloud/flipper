require 'helper'
require 'flipper/gate_values'

describe Flipper::GateValues do
  {
    nil => false,
    "" => false,
    0 => false,
    1 => true,
    "0" => false,
    "1" => true,
    true => true,
    false => false,
    "true" => true,
    "false" => false,
  }.each do |value, expected|
    context "with #{value.inspect} boolean" do
      it "returns #{expected}" do
        described_class.new(boolean: value).boolean.should be(expected)
      end
    end
  end

  {
    nil => 0,
    "" => 0,
    0 => 0,
    1 => 1,
    "1" => 1,
    "99" => 99,
  }.each do |value, expected|
    context "with #{value.inspect} percentage of time" do
      it "returns #{expected}" do
        described_class.new(percentage_of_time: value).percentage_of_time.should be(expected)
      end
    end
  end

  {
    nil => 0,
    "" => 0,
    0 => 0,
    1 => 1,
    "1" => 1,
    "99" => 99,
  }.each do |value, expected|
    context "with #{value.inspect} percentage of actors" do
      it "returns #{expected}" do
        described_class.new(percentage_of_actors: value).percentage_of_actors.should be(expected)
      end
    end
  end

  {
    nil => Set.new,
    "" => Set.new,
    Set.new([1, 2]) => Set.new([1, 2]),
    [1, 2] => Set.new([1, 2])
  }.each do |value, expected|
    context "with #{value.inspect} actors" do
      it "returns #{expected}" do
        described_class.new(actors: value).actors.should eq(expected)
      end
    end
  end

  {
    nil => Set.new,
    "" => Set.new,
    Set.new([:admins, :preview_features]) => Set.new([:admins, :preview_features]),
    [:admins, :preview_features] => Set.new([:admins, :preview_features])
  }.each do |value, expected|
    context "with #{value.inspect} groups" do
      it "returns #{expected}" do
        described_class.new(groups: value).groups.should eq(expected)
      end
    end
  end

  it "raises argument error for percentage of time value that cannot be converted to an integer" do
    expect {
      described_class.new(percentage_of_time: ["asdf"])
    }.to raise_error(ArgumentError, %Q(["asdf"] cannot be converted to an integer))
  end

  it "raises argument error for percentage of actors value that cannot be converted to an integer" do
    expect {
      described_class.new(percentage_of_actors: ["asdf"])
    }.to raise_error(ArgumentError, %Q(["asdf"] cannot be converted to an integer))
  end

  it "raises argument error for actors value that cannot be converted to a set" do
    expect {
      described_class.new(actors: "asdf")
    }.to raise_error(ArgumentError, %Q("asdf" cannot be converted to a set))
  end

  it "raises argument error for groups value that cannot be converted to a set" do
    expect {
      described_class.new(groups: "asdf")
    }.to raise_error(ArgumentError, %Q("asdf" cannot be converted to a set))
  end

  describe "#[]" do
    it "can read the boolean value" do
      described_class.new(boolean: true)[:boolean].should be(true)
      described_class.new(boolean: true)["boolean"].should be(true)
    end

    it "can read the actors value" do
      described_class.new(actors: Set[1, 2])[:actors].should eq(Set[1, 2])
      described_class.new(actors: Set[1, 2])["actors"].should eq(Set[1, 2])
    end

    it "can read the groups value" do
      described_class.new(groups: Set[:admins])[:groups].should eq(Set[:admins])
      described_class.new(groups: Set[:admins])["groups"].should eq(Set[:admins])
    end

    it "can read the percentage of time value" do
      described_class.new(percentage_of_time: 15)[:percentage_of_time].should eq(15)
      described_class.new(percentage_of_time: 15)["percentage_of_time"].should eq(15)
    end

    it "can read the percentage of actors value" do
      described_class.new(percentage_of_actors: 15)[:percentage_of_actors].should eq(15)
      described_class.new(percentage_of_actors: 15)["percentage_of_actors"].should eq(15)
    end

    it "returns nil for value that is not present" do
      described_class.new({})["not legit"].should be(nil)
    end
  end
end
