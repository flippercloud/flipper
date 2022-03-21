RSpec.describe Flipper::Api::V1::Decorators::Feature do
  describe "#as_json" do
    context "with exclude_gates set to true" do
      subject { described_class.new(flipper[:my_feature]).as_json(exclude_gates: true) }

      it "returns json WITHOUT feature gate data" do
        expect(subject.keys).to_not include("gates")
      end
    end

    context "with exclude_gates set to false" do
      subject { described_class.new(flipper[:my_feature]).as_json(exclude_gates: false) }

      it "returns json WITH feature gate data" do
        expect(subject.keys).to include("gates")
      end
    end

    context "without exclude_gates set" do
      subject { described_class.new(flipper[:my_feature]).as_json }

      it "returns json WITH feature gate data" do
        expect(subject.keys).to include("gates")
      end
    end
  end
end
