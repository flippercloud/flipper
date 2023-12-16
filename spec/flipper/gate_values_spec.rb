require 'flipper/gate_values'

RSpec.describe Flipper::GateValues do
  {
    nil => false,
    '' => false,
    0 => false,
    1 => true,
    '0' => false,
    '1' => true,
    true => true,
    false => false,
    'true' => true,
    'false' => false,
  }.each do |value, expected|
    context "with #{value.inspect} boolean" do
      it "returns #{expected}" do
        expect(described_class.new(boolean: value).boolean).to be(expected)
      end
    end
  end

  {
    nil => 0,
    '' => 0,
    0 => 0,
    1 => 1,
    '1' => 1,
    '99' => 99,
  }.each do |value, expected|
    context "with #{value.inspect} percentage of time" do
      it "returns #{expected}" do
        expect(described_class.new(percentage_of_time: value).percentage_of_time).to be(expected)
      end
    end
  end

  {
    nil => 0,
    '' => 0,
    0 => 0,
    1 => 1,
    '1' => 1,
    '99' => 99,
  }.each do |value, expected|
    context "with #{value.inspect} percentage of actors" do
      it "returns #{expected}" do
        expect(described_class.new(percentage_of_actors: value).percentage_of_actors)
          .to be(expected)
      end
    end
  end

  {
    nil => Set.new,
    '' => Set.new,
    Set.new([1, 2]) => Set.new([1, 2]),
    [1, 2] => Set.new([1, 2]),
  }.each do |value, expected|
    context "with #{value.inspect} actors" do
      it "returns #{expected}" do
        expect(described_class.new(actors: value).actors).to eq(expected)
      end
    end
  end

  {
    nil => Set.new,
    '' => Set.new,
    Set.new([:admins, :preview_features]) => Set.new([:admins, :preview_features]),
    [:admins, :preview_features] => Set.new([:admins, :preview_features]),
  }.each do |value, expected|
    context "with #{value.inspect} groups" do
      it "returns #{expected}" do
        expect(described_class.new(groups: value).groups).to eq(expected)
      end
    end
  end

  it 'raises argument error for percentage of time value that cannot be converted to an integer' do
    expect do
      described_class.new(percentage_of_time: ['asdf'])
    end.to raise_error(ArgumentError, %(["asdf"] cannot be converted to a number))
  end

  it 'raises argument error for percentage of actors value that cannot be converted to an int' do
    expect do
      described_class.new(percentage_of_actors: ['asdf'])
    end.to raise_error(ArgumentError, %(["asdf"] cannot be converted to a number))
  end

  it 'raises argument error for actors value that cannot be converted to a set' do
    expect do
      described_class.new(actors: 'asdf')
    end.to raise_error(ArgumentError, %("asdf" cannot be converted to a set))
  end

  it 'raises argument error for groups value that cannot be converted to a set' do
    expect do
      described_class.new(groups: 'asdf')
    end.to raise_error(ArgumentError, %("asdf" cannot be converted to a set))
  end
end
