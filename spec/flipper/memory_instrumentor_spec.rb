require 'helper'
require 'flipper/memory_instrumentor'

describe Flipper::MemoryInstrumentor do
  describe "#initialize" do
    it "sets events to empty array" do
      instrumentor = described_class.new
      instrumentor.events.should eq([])
    end
  end

  describe "#instrument" do
    it "adds to events" do
      instrumentor = described_class.new
      name         = 'user.signup'
      payload      = {:email => 'john@doe.com'}
      block_result = :yielded

      result = instrumentor.instrument(name, payload) { block_result }
      result.should eq(block_result)

      event = described_class::Event.new(name, payload, block_result)
      instrumentor.events.should eq([event])
    end
  end
end
