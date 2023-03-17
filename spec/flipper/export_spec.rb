RSpec.describe Flipper::Export do
  it "can initialize" do
    export = described_class.new(input: "{}", format: :json, version: 1)
    expect(export.input).to eq("{}")
    expect(export.format).to eq(:json)
    expect(export.version).to eq(1)
  end

  it "raises not implemented for features" do
    export = described_class.new(input: "{}", format: :json, version: 1)
    expect { export.features }.to raise_error(NotImplementedError)
  end
end
