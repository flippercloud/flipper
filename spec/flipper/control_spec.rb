require 'helper'
require 'flipper/control'
require 'flipper/adapters/memory'
require 'flipper/instrumenters/memory'

RSpec.describe Flipper::Control do
  subject { described_class.new(:poll_interval, adapter) }

  let(:adapter) { Flipper::Adapters::Memory.new }

  describe "#initialize" do
    it "sets name" do
      control = described_class.new(:poll_interval, adapter)
      expect(control.name).to eq(:poll_interval)
    end

    it "sets adapter" do
      control = described_class.new(:poll_interval, adapter)
      expect(control.adapter).to eq(adapter)
    end

    it "defaults instrumenter" do
      control = described_class.new(:poll_interval, adapter)
      expect(control.instrumenter).to be(Flipper::Instrumenters::Noop)
    end

    context "with overriden instrumenter" do
      let(:instrumenter) { double('Instrumentor', :instrument => nil) }

      it "overrides default instrumenter" do
        control = described_class.new(:poll_interval, adapter, {
          :instrumenter => instrumenter,
        })
        expect(control.instrumenter).to be(instrumenter)
      end
    end
  end

  describe "#to_s" do
    it "returns name as string" do
      control = described_class.new(:poll_interval, adapter)
      expect(control.to_s).to eq("poll_interval")
    end
  end

  describe "#to_param" do
    it "returns name as string" do
      control = described_class.new(:poll_interval, adapter)
      expect(control.to_param).to eq("poll_interval")
    end
  end

  describe "instrumentation" do
    let(:instrumenter) { Flipper::Instrumenters::Memory.new }

    subject {
      described_class.new(:poll_interval, adapter, :instrumenter => instrumenter)
    }

    it "is recorded for value" do
      subject.value

      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.name).to eq('control_operation.flipper')
      expect(event.payload[:control_name]).to eq(:poll_interval)
      expect(event.payload[:operation]).to eq(:value)
      expect(event.payload.key?(:result)).to be(true)

      subject.set("10")
      subject.value
      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.payload[:result]).to eq("10")
    end

    it "is recorded for set" do
      subject.set("10")

      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.name).to eq('control_operation.flipper')
      expect(event.payload[:control_name]).to eq(:poll_interval)
      expect(event.payload[:operation]).to eq(:set)
      expect(event.payload[:result]).not_to be_nil
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      string = subject.inspect
      expect(string).to include('Flipper::Control')
      expect(string).to include('name=:poll_interval')
      expect(string).to include('value=nil')
      expect(string).to include("adapter=#{subject.adapter.name.inspect}")

      subject.set "10"
      string = subject.inspect
      expect(string).to include('value="10"')
    end
  end
end
