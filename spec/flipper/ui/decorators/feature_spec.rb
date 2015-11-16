require 'helper'
require 'flipper/adapters/memory'

RSpec.describe Flipper::UI::Decorators::Feature do
  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }
  let(:flipper) { build_flipper }
  let(:feature) { flipper[:some_awesome_feature] }

  subject {
    described_class.new(feature)
  }

  describe "#initialize" do
    it "sets the feature" do
      expect(subject.feature).to be(feature)
    end
  end

  describe "#pretty_name" do
    it "capitalizes each word separated by underscores" do
      expect(subject.pretty_name).to eq('Some Awesome Feature')
    end
  end

  describe "#as_json" do
    before do
      @result = subject.as_json
    end

    it "returns Hash" do
      expect(@result).to be_instance_of(Hash)
    end

    it "includes id" do
      expect(@result['id']).to eq('some_awesome_feature')
    end

    it "includes pretty name" do
      expect(@result['name']).to eq('Some Awesome Feature')
    end

    it "includes state" do
      expect(@result['state']).to eq('off')
    end

    it "includes gates" do
      gates = subject.gates.map { |gate|
        value = subject.gate_values[gate.key]
        Flipper::UI::Decorators::Gate.new(gate, value).as_json
      }
      expect(@result['gates']).to eq(gates)
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
      expect((on <=> conditional)).to be(-1)
    end

    it "sorts :on before :off" do
      expect((on <=> conditional)).to be(-1)
    end

    it "sorts :conditional before :off" do
      expect((on <=> conditional)).to be(-1)
    end

    it "sorts on key for identical states" do
      expect((on <=> on_b)).to be(-1)
    end
  end
end
