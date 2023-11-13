require 'flipper/serializers/gzip'

RSpec.describe Flipper::Serializers::Gzip do
  it "serializes and deserializes" do
    serialized = described_class.serialize("my data")
    expect(described_class.deserialize(serialized)).to eq("my data")
  end
end
