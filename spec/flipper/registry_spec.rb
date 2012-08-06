require 'helper'
require 'flipper/registry'

describe Flipper::Registry do
  subject { Flipper::Registry.new(source) }

  let(:source) { {} }

  describe "#add" do
    it "adds to source" do
      value = 'thing'
      subject.add(:admins, value)
      source[:admins].should eq(value)
    end

    it "raises exception if key already registered" do
      subject.add(:admins, 'thing')

      expect {
        subject.add(:admins, 'again')
      }.to raise_error(Flipper::Registry::DuplicateKey)
    end
  end

  describe "#get" do
    context "key registered" do
      before do
        source[:admins] = 'thing'
      end

      it "returns value" do
        subject.get(:admins).should eq('thing')
      end
    end

    context "key not registered" do
      it "raises key not found" do
        subject.get(:admins).should be_nil
      end
    end
  end

  describe "#each" do
    before do
      source[:admins] = 'admins'
      source[:devs] = 'devs'
    end

    it "iterates source keys and values" do
      results = {}
      subject.each do |key, value|
        results[key] = value
      end
      results.should eq({
        :admins => 'admins',
        :devs => 'devs',
      })
    end
  end

  describe "#keys" do
    before do
      source[:admins] = 'admins'
      source[:devs] = 'devs'
    end

    it "returns the keys" do
      subject.keys.should eq([:admins, :devs])
    end
  end

  describe "#values" do
    before do
      source[:admins] = 'admins'
      source[:devs] = 'devs'
    end

    it "returns the values" do
      subject.values.should eq(['admins', 'devs'])
    end
  end

  describe "enumeration" do
    before do
      source[:admins] = 'admins'
      source[:devs] = 'devs'
    end

    it "works" do
      keys = []
      values = []

      subject.map do |key, value|
        keys << key
        values << value
      end

      keys.should eq([:admins, :devs])
      values.should eq(['admins', 'devs'])
    end
  end

  describe "#clear" do
    before do
      source[:admins] = 'admins'
    end

    it "clears the source" do
      subject.clear
      source.should be_empty
    end
  end
end
