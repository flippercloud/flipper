require 'helper'
require 'flipper/types/percentage_of_actors'

describe Flipper::Types::Percentage do
  subject {
    described_class.new(5)
  }
  it_should_behave_like 'a percentage'

  describe ".wrap" do
    context "with percentage instance" do
      it "returns percentage instance" do
        described_class.wrap(subject).should eq(subject)
      end
    end

    context "with Integer" do
      it "returns percentage instance" do
        described_class.wrap(subject.value).should eq(subject)
      end
    end

    context "with String" do
      it "returns percentage instance" do
        described_class.wrap(subject.value.to_s).should eq(subject)
      end
    end
  end

  describe "#eql?" do
    it "returns true for same class and value" do
      subject.eql?(described_class.new(subject.value)).should eq(true)
    end

    it "returns false for different value" do
      subject.eql?(described_class.new(subject.value + 1)).should eq(false)
    end

    it "returns false for different class" do
      subject.eql?(Object.new).should eq(false)
    end

    it "is aliased to ==" do
      (subject == described_class.new(subject.value)).should eq(true)
    end
  end
end
