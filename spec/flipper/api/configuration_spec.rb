require 'helper'

RSpec.describe Flipper::Api::Configuration do
  let(:configuration) { described_class.new }

  describe "#include_feature_gate_data" do
    it "has default value" do
      expect(configuration.include_feature_gate_data).to eq(true)
    end

    it "can be updated" do
      configuration.include_feature_gate_data = false
      expect(configuration.include_feature_gate_data).to eq(false)
    end
  end
end
