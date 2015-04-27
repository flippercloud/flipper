require 'helper'
require 'flipper/adapters/memory'
require 'flipper/ui/decorators/gate'

describe Flipper::UI::Decorators::Gate do
  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }
  let(:flipper) { build_flipper }
  let(:feature) { flipper[:some_awesome_feature] }
  let(:gate) { feature.gate(:boolean) }

  subject {
    described_class.new(gate, false)
  }

  describe "#initialize" do
    it "sets gate" do
      subject.gate.should be(gate)
    end

    it "sets value" do
      subject.value.should eq(false)
    end
  end

  describe "#as_json" do
    before do
      @result = subject.as_json
    end

    it "returns Hash" do
      @result.should be_instance_of(Hash)
    end

    it "includes key" do
      @result['key'].should eq('boolean')
    end

    it "includes pretty name" do
      @result['name'].should eq('boolean')
    end

    it "includes value" do
      @result['value'].should be(false)
    end
  end
end
