require 'helper'
require 'flipper/adapters/memoized'
require 'flipper/adapters/memory'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Memoized do
  let(:cache)   { {} }
  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }
  let(:flipper) { Flipper.new(adapter) }

  subject { described_class.new(adapter, cache) }

  def read_key(key)
    source[key.to_s]
  end

  def write_key(key, value)
    source[key.to_s] = value
  end

  it_should_behave_like 'a flipper adapter'

  describe "#get" do
    before do
      @feature = flipper[:stats]
      @result = subject.get(@feature)
    end

    it "memoizes feature" do
      cache[@feature].should be(@result)
    end
  end

  describe "#read" do
    before do
      source['foo'] = 'bar'
      subject.read('foo')
    end

    it "memoizes key" do
      cache['foo'].should eq(source['foo'])
      cache['foo'].should eq('bar')
    end
  end

  describe "#set_members" do
    before do
      source['foo'] = Set['1', '2']
      subject.set_members('foo')
    end

    it "memoizes key" do
      cache['foo'].should eq(source['foo'])
      cache['foo'].should eq(Set['1', '2'])
    end
  end

  describe "#write" do
    before do
      source['foo'] = 'bar'
      @result = subject.read('foo')
      subject.write('foo', 'bar')
    end

    it "unmemoizes key" do
      cache.key?('foo').should be_false
    end
  end

  describe "#delete" do
    before do
      source['foo'] = 'bar'
      @result = subject.read('foo')
      subject.delete('foo')
    end

    it "unmemoizes key" do
      cache.key?('foo').should be_false
    end
  end

  describe "#set_add" do
    before do
      source['foo'] = Set['1', '2']
      @result = subject.set_members('foo')
      subject.set_add('foo', '3')
    end

    it "unmemoizes key" do
      cache.key?('foo').should be_false
    end
  end

  describe "#set_delete" do
    before do
      source['foo'] = Set['1', '2']
      subject.set_delete('foo', '2')
    end

    it "unmemoizes key" do
      cache.key?('foo').should be_false
    end
  end
end
