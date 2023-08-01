RSpec.describe Flipper::Exporter do
  describe ".build" do
    it "builds instance of exporter" do
      exporter = described_class.build(format: :json, version: 1)
      expect(exporter).to be_instance_of(Flipper::Exporters::Json::V1)
    end

    it "raises if format not found" do
      expect { described_class.build(format: :nope, version: 1) }.to raise_error(KeyError)
    end

    it "raises if version not found" do
      expect { described_class.build(format: :json, version: 0) }.to raise_error(KeyError)
    end
  end
end
