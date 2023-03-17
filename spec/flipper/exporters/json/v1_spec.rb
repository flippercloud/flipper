require 'flipper/exporters/json/v1'

RSpec.describe Flipper::Exporters::Json::V1 do
  subject { described_class.new }

  it "has a version number" do
    adapter = Flipper::Adapters::Memory.new
    result = subject.call(adapter)
    data = JSON.parse(result)
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

    result = subject.call(adapter)

    data = JSON.parse(result)
    expect(data["features"]).to eq({
      "google_analytics" => {"actors"=>[], "boolean"=>nil, "groups"=>[], "percentage_of_actors"=>nil, "percentage_of_time"=>nil},
      "plausible" => {"actors" => [], "boolean" => "true", "groups" => [], "percentage_of_actors" => nil, "percentage_of_time" => nil},
      "search" => {"actors" => ["User;1", "User;100"], "boolean" => nil, "groups" => ["admins", "employees"], "percentage_of_actors" => "10", "percentage_of_time" => "15"},
    })
  end
end
