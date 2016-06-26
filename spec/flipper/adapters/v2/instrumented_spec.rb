require 'helper'
require 'flipper/adapters/v2/memory'
require 'flipper/adapters/v2/instrumented'
require 'flipper/instrumenters/memory'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::Instrumented do
  let(:memory) { Flipper::Adapters::V2::Memory.new }
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }

  subject { described_class.new(memory, instrumenter: instrumenter) }

  it_should_behave_like 'a v2 flipper adapter'

  it "forwards missing methods to underlying adapter" do
    adapter = Class.new do
      def foo
        :foo
      end
    end.new
    instrumented = described_class.new(adapter)
    expect(instrumented.foo).to eq(:foo)
  end

  describe "#name" do
    it "is instrumented" do
      expect(subject.name).to be(:instrumented)
    end
  end

  {
    :get => ["foo"],
    :set => ["foo", "bar"],
    :del => ["foo"],
    :mget => [["foo"]],
    :mset => [{"foo" => "bar"}],
    :mdel => [["foo"]],
    :smembers => ["foo"],
    :sadd => ["foo", "bar"],
    :srem => ["foo", "bar"],
  }.each do |name, args|
    describe "##{name}" do
      it "records instrumentation" do
        result = subject.send(name, *args)
        event = instrumenter.events.last
        expect(event).not_to be_nil
        expect(event.name).to eq('adapter_operation.flipper')
        expect(event.payload[:operation]).to eq(name)
        expect(event.payload[:adapter_name]).to eq(:memory)
        expect(event.payload[:result]).to be(result)
      end
    end
  end
end
