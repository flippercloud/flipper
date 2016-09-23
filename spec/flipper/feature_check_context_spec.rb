require 'helper'

RSpec.describe Flipper::FeatureCheckContext do
  let(:feature_name) { :new_profiles }
  let(:values) { Flipper::GateValues.new({}) }
  let(:thing) { Struct.new(:flipper_id).new("5") }
  let(:options) {
    {
      feature_name: feature_name,
      values: values,
      thing: thing,
    }
  }

  it "initializes just fine" do
    instance = described_class.new(options)
    expect(instance.feature_name).to eq(feature_name)
    expect(instance.values).to eq(values)
    expect(instance.thing).to eq(thing)
  end

  it "requires feature_name" do
    options.delete(:feature_name)
    expect {
      described_class.new(options)
    }.to raise_error(KeyError)
  end

  it "requires values" do
    options.delete(:values)
    expect {
      described_class.new(options)
    }.to raise_error(KeyError)
  end

  it "requires thing" do
    options.delete(:thing)
    expect {
      described_class.new(options)
    }.to raise_error(KeyError)
  end
end
