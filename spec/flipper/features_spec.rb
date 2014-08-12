require 'helper'
require 'flipper/feature'
require 'flipper/adapters/memory'
require 'flipper/instrumenters/memory'

describe Flipper::Features do
  subject { described_class.new([], adapter) }
  let(:features) { subject }
  let(:adapter) { Flipper::Adapters::Memory.new }

  describe "#declare" do
    let(:names) { ["feature_1", "feature_2", "feature_3"] }

    it "creates new features for each name" do
      features.should be_empty
      features.declare(*names)
      names.each do |name|
        features.map(&:name).should =~ names
      end
    end

    it "returns itself" do
      features.declare(*names).should equal features
    end
  end
end
