require 'helper'
require 'flipper/instrumentors/memory'

describe Flipper::Gates::PercentageOfRandom do
  describe "instrumentation" do
    let(:adapter) { double('Adapter', :read => 5) }
    let(:feature) { double('Feature', :name => :search, :adapter => adapter) }
    let(:instrumentor) { Flipper::Instrumentors::Memory.new }

    subject {
      described_class.new(feature, :instrumentor => instrumentor)
    }

    it "is recorded for open" do
      thing = Struct.new(:flipper_id).new('22')
      subject.open?(thing)

      event = instrumentor.events.last
      event.should_not be_nil
      event.name.should eq('open.percentage_of_random.gate.flipper')
      event.payload.should eq({
        :thing => thing,
      })
    end
  end
end
