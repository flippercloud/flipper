require 'helper'
require 'flipper/adapters/memory'

describe Flipper::UI::Decorators::Feature do
  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }
  let(:flipper) { build_flipper }
  let(:feature) { flipper[:some_awesome_feature] }

  subject {
    described_class.new(feature)
  }

  describe "#initialize" do
    it "sets the feature" do
      subject.feature.should be(feature)
    end
  end

  describe "#pretty_name" do
    it "capitalizes each word separated by underscores" do
      subject.pretty_name.should eq('Some Awesome Feature')
    end
  end

  describe "#as_json" do
    before do
      @result = subject.as_json
    end

    it "returns Hash" do
      @result.should be_instance_of(Hash)
    end

    it "includes id" do
      @result['id'].should eq('some_awesome_feature')
    end

    it "includes pretty name" do
      @result['name'].should eq('Some Awesome Feature')
    end

    it "includes state" do
      @result['state'].should eq('off')
    end

    it "includes gates" do
      gates = subject.gates.map { |gate|
        value = subject.gate_values[gate.key]
        Flipper::UI::Decorators::Gate.new(gate, value).as_json
      }
      @result['gates'].should eq(gates)
    end
  end

  describe "#<=>" do
    let(:on) {
      flipper.enable(:on_a)
      described_class.new(flipper[:on_a])
    }

    let(:on_b) {
      flipper.enable(:on_b)
      described_class.new(flipper[:on_b])
    }

    let(:conditional) {
      flipper.enable_percentage_of_time :conditional_a, 5
      described_class.new(flipper[:conditional_a])
    }

    let(:off) {
      described_class.new(flipper[:off_a])
    }

    it "sorts :on before :conditional" do
      (on <=> conditional).should be(-1)
    end

    it "sorts :on before :off" do
      (on <=> conditional).should be(-1)
    end

    it "sorts :conditional before :off" do
      (on <=> conditional).should be(-1)
    end

    it "sorts on key for identical states" do
      (on <=> on_b).should be(-1)
    end
  end
end
