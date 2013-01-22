require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Instrumenters::Memory do
  describe "#initialize" do
    it "sets events to empty array" do
      instrumenter = described_class.new
      instrumenter.events.should eq([])
    end
  end

  describe "#instrument" do
    it "adds to events" do
      instrumenter = described_class.new
      name         = 'user.signup'
      payload      = {:email => 'john@doe.com'}
      block_result = :yielded

      result = instrumenter.instrument(name, payload) { block_result }
      result.should eq(block_result)

      event = described_class::Event.new(name, payload, block_result)
      instrumenter.events.should eq([event])
    end
  end
end
