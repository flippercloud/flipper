require 'flipper/serializers/json'

RSpec.describe Flipper::Serializers::Json do
  it "serializes and deserializes" do
    serialized = described_class.serialize("my data")
    expect(described_class.deserialize(serialized)).to eq("my data")
  end
end
