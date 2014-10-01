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

    it "converts key to symbol" do
      value = 'thing'
      subject.add('admins', value)
      source[:admins].should eq(value)
    end

    it "raises exception if key already registered" do
      subject.add(:admins, 'thing')

      expect {
        subject.add('admins', 'again')
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

      it "returns value if given string key" do
        subject.get('admins').should eq('thing')
      end
    end

    context "key not registered" do
      it "raises key not found" do
        expect {
          subject.get(:admins)
        }.to raise_error(Flipper::Registry::KeyNotFound)
      end
    end
  end

  describe "#key?" do
    before do
      source[:admins] = "admins"
    end

    it "returns true if the key exists" do
      subject.key?(:admins).should eq true
    end

    it "returns false if the key does not exists" do
      subject.key?(:unknown_key).should eq false
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
      subject.keys.map(&:to_s).sort.should eq(['admins', 'devs'])
    end

    it "returns the keys as symbols" do
      subject.keys.each do |key|
        key.should be_instance_of(Symbol)
      end
    end
  end

  describe "#values" do
    before do
      source[:admins] = 'admins'
      source[:devs] = 'devs'
    end

    it "returns the values" do
      subject.values.map(&:to_s).sort.should eq(['admins', 'devs'])
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

      keys.map(&:to_s).sort.should eq(['admins', 'devs'])
      values.sort.should eq(['admins', 'devs'])
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
