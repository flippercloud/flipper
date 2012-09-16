require 'helper'
require 'flipper/types/percentage_of_actors'

describe Flipper::Types::Percentage do
  subject {
    described_class.new(5)
  }
  it_should_behave_like 'a percentage'

  describe "#eql?" do
    it "returns true for same class and value" do
      subject.eql?(described_class.new(subject.value)).should be_true
    end

    it "returns false for different value" do
      subject.eql?(described_class.new(subject.value + 1)).should be_false
    end

    it "returns false for different class" do
      subject.eql?(Object.new).should be_false
    end

    it "is aliased to ==" do
      (subject == described_class.new(subject.value)).should be_true
    end
  end
end
