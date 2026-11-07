RSpec.describe Flipper::Snapshot do
  it "accepts nil, zero and positive integer revisions" do
    [nil, 0, 42].each do |version|
      expect(described_class.new(features: {}, version: version).version).to eq(version)
    end
  end

  it "rejects malformed revisions before they reach local storage" do
    [-1, 1.5, "10", false].each do |version|
      expect { described_class.new(features: {}, version: version) }.to raise_error(ArgumentError)
    end
  end
end
