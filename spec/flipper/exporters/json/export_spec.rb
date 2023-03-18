require 'flipper/exporters/json/v1'

RSpec.describe Flipper::Exporters::Json::Export do
  let(:contents) {
    <<~JSON
      {
        "version":1,
        "features":{
          "search":{"boolean":null,"groups":["admins","employees"],"actors":["User;1","User;100"],"percentage_of_actors":"10","percentage_of_time":"15"},
          "plausible":{"boolean":"true","groups":[],"actors":[],"percentage_of_actors":null,"percentage_of_time":null},
          "google_analytics":{"boolean":null,"groups":[],"actors":[],"percentage_of_actors":null,"percentage_of_time":null}
        }
      }
    JSON
  }

  it "can initialize" do
    export = described_class.new(contents: contents)
    expect(export.format).to eq(:json)
    expect(export.version).to be(1)
  end

  it "can initialize with version" do
    export = described_class.new(contents: contents, version: 1)
    expect(export.version).to be(1)
  end

  it "can build features from contents" do
    export = Flipper::Exporters::Json::Export.new(contents: contents)
    expect(export.features).to eq({
      "search" => {actors: Set["User;1", "User;100"], boolean: nil, groups: Set["admins", "employees"], percentage_of_actors: "10", percentage_of_time: "15"},
      "plausible" => {actors: Set.new, boolean: "true", groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
      "google_analytics" => {actors: Set.new, boolean: nil, groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
    })
  end

  it "can build an adapter from features" do
    export = Flipper::Exporters::Json::Export.new(contents: contents)
    expect(export.adapter).to be_instance_of(Flipper::Adapters::Memory)
    expect(export.adapter.get_all).to eq({
      "plausible" => {actors: Set.new, boolean: "true", groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
      "search" => {actors: Set["User;1", "User;100"], boolean: nil, groups: Set["admins", "employees"], percentage_of_actors: "10", percentage_of_time: "15"},
      "google_analytics" => {actors: Set.new, boolean: nil, groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
    })
  end

  it "raises for invalid json" do
    export = described_class.new(contents: "bad contents")
    expect {
      export.features
    }.to raise_error(Flipper::Exporters::Json::JsonError)
  end

  it "raises for missing features key" do
    export = described_class.new(contents: "{}")
    expect {
      export.features
    }.to raise_error(Flipper::Exporters::Json::InvalidError)
  end
end
