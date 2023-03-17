require 'flipper/exporters/json/v1'

RSpec.describe Flipper::Exporters::Json::Export do
  let(:input) {
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
    export = described_class.new(input: input)
    expect(export.format).to eq(:json)
    expect(export.version).to be(1)
  end

  it "can initialize with version" do
    export = described_class.new(input: input, version: 1)
    expect(export.version).to be(1)
  end

  it "can build features from input" do
    export = Flipper::Exporters::Json::Export.new(input: input)
    expect(export.features).to eq({
      "search" => {actors: ["User;1", "User;100"], boolean: nil, groups: ["admins", "employees"], percentage_of_actors: "10", percentage_of_time: "15"},
      "plausible" => {actors: [], boolean: "true", groups: [], percentage_of_actors: nil, percentage_of_time: nil},
      "google_analytics" => {actors: [], boolean: nil, groups: [], percentage_of_actors: nil, percentage_of_time: nil},
    })
  end

  it "can build an adapter from features" do
    export = Flipper::Exporters::Json::Export.new(input: input)
    expect(export.adapter).to be_instance_of(Flipper::Adapters::Memory)
    expect(export.adapter.get_all).to eq({
      "search" => {actors: ["User;1", "User;100"], boolean: nil, groups: ["admins", "employees"], percentage_of_actors: "10", percentage_of_time: "15"},
      "plausible" => {actors: [], boolean: "true", groups: [], percentage_of_actors: nil, percentage_of_time: nil},
      "google_analytics" => {actors: [], boolean: nil, groups: [], percentage_of_actors: nil, percentage_of_time: nil},
    })
  end
end
