require 'flipper/exporters/json/v1'

RSpec.describe Flipper::Exporters::Json::V1 do
  subject { described_class.new }

  it "has a version number" do
    adapter = Flipper::Adapters::Memory.new
    export = subject.call(adapter)
    data = JSON.parse(export.contents)
    expect(data["version"]).to eq(1)
  end

  it "exports features and gates" do
    adapter = Flipper::Adapters::Memory.new
    flipper = Flipper.new(adapter)
    flipper.enable_percentage_of_actors :search, 10
    flipper.enable_percentage_of_time :search, 15
    flipper.enable_actor :search, Flipper::Actor.new('User;1')
    flipper.enable_actor :search, Flipper::Actor.new('User;100')
    flipper.enable_group :search, :admins
    flipper.enable_group :search, :employees
    flipper.enable :plausible
    flipper.disable :google_analytics

    export = subject.call(adapter)

    expect(export.features).to eq({
      "google_analytics" => {actors: Set.new, boolean: nil, expression: nil, groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
      "plausible" => {actors: Set.new, boolean: "true", expression: nil, groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
      "search" => {actors: Set["User;1", "User;100"], boolean: nil, expression: nil, groups: Set["admins", "employees"], percentage_of_actors: "10", percentage_of_time: "15"},
    })
  end
end
