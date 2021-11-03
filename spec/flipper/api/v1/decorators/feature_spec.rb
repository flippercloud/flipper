require 'helper'

RSpec.describe Flipper::Api::V1::Decorators::Feature do
  describe "#as_json" do
    subject { described_class.new(flipper[:my_feature]).as_json }

    context "with include_feature_gate_data set to true" do
      before do
        @original_include_feature_gate_data = Flipper::Api.configuration.include_feature_gate_data
        Flipper::Api.configuration.include_feature_gate_data = true
      end

      after do
        Flipper::Api.configuration.include_feature_gate_data = @original_include_feature_gate_data
      end

      it "json has feature gate data" do
        expect(subject.keys).to include("gates")
      end
    end

    context "with include_feature_gate_data set to false" do
      before do
        @original_include_feature_gate_data = Flipper::Api.configuration.include_feature_gate_data
        Flipper::Api.configuration.include_feature_gate_data = false
      end

      after do
        Flipper::Api.configuration.include_feature_gate_data = @original_include_feature_gate_data
      end

      it "json DOES NOT have feature gate data" do
        expect(subject.keys).to_not include("gates")
      end
    end
  end
end
