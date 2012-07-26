require 'helper'
require 'flipper/adapters/memory'

describe Flipper::Adapters::Memory do
  let(:source) { Hash.new }

  subject { Flipper::Adapters::Memory.new(source) }

  describe "#write" do
    it "key to value in store" do
      subject.write('foo', true)
      source['foo'].should be_true
    end
  end

  describe "#read" do
    it "returns nil if key not in store" do
      subject.read('foo').should be_nil
    end

    it "returns value if key in store" do
      source['foo'] = 'bar'
      subject.read('foo').should eq('bar')
    end
  end

  describe "#delete" do
    it "deletes key" do
      source['foo'] = 'bar'
      subject.delete('foo')
      source['foo'].should be_nil
    end
  end

  describe "#set_add" do
    it "adds value to store" do
      subject.set_add('foo', 1)
      source['foo'].should eq(Set[1])
    end

    it "does not add same value more than once" do
      subject.set_add('foo', 1)
      subject.set_add('foo', 1)
      subject.set_add('foo', 1)
      subject.set_add('foo', 2)
      source['foo'].should eq(Set[1, 2])
    end
  end

  describe "#set_delete" do
    it "removes value from set if key in store" do
      source['foo'] = Set[1, 2]
      subject.set_delete('foo', 1)
      source['foo'].should eq(Set[2])
    end

    it "works fine if key not in store" do
      subject.set_delete('foo', 'bar')
    end
  end

  describe "#set_members" do
    it "defaults to empty set" do
      subject.set_members('foo').should eq(Set.new)
    end

    it "returns set if in store" do
      source['foo'] = Set[1, 2]
      subject.set_members('foo').should eq(Set[1, 2])
    end
  end
end
