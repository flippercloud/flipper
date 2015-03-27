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
    context "with #{value.inspect} percentage of random" do
      it "returns #{expected}" do
        described_class.new(percentage_of_random: value).percentage_of_random.should be(expected)
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

  it "raises argument error for percentage of random value that cannot be converted to an integer" do
    expect {
      described_class.new(percentage_of_random: ["asdf"])
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
end
