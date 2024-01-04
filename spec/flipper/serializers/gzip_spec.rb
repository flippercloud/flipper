require 'flipper/serializers/gzip'

RSpec.describe Flipper::Serializers::Gzip do
  it "serializes and deserializes" do
    serialized = described_class.serialize("my data")
    expect(described_class.deserialize(serialized)).to eq("my data")
  end

  it "doesn't fail with nil" do
    expect(described_class.serialize(nil)).to be(nil)
    expect(described_class.deserialize(nil)).to be(nil)
  end
end
