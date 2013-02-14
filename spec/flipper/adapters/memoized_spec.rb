require 'helper'
require 'flipper/adapters/memoized'
require 'flipper/adapters/memory'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Memoized do
  let(:cache)   { {} }
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }

  subject { described_class.new(adapter, cache) }

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

  describe "#enable" do
    before do
      @feature = flipper[:stats]
      gate = @feature.gate(:boolean)

      cache[@feature] = {:some => 'thing'}
      subject.enable(@feature, gate, Flipper::Types::Boolean.new)
    end

    it "unmemoizes feature in cache" do
      cache[@feature].should be_nil
    end
  end

  describe "#disable" do
    before do
      @feature = flipper[:stats]
      gate = @feature.gate(:boolean)

      cache[@feature] = {:some => 'thing'}
      subject.disable(@feature, gate, Flipper::Types::Boolean.new)
    end

    it "unmemoizes feature in cache" do
      cache[@feature].should be_nil
    end
  end
end
