require 'helper'
require 'flipper/adapters/pstore'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::PStore do
  subject {
    dir = FlipperRoot.join("tmp").tap { |d| d.mkpath }
    described_class.new(dir.join("flipper.pstore"))
  }

  it_should_behave_like 'a flipper adapter'

  it "defaults path to flipper.pstore" do
    expect(described_class.new.path).to eq("flipper.pstore")
  end
end
