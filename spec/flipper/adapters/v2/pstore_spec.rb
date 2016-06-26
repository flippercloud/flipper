require 'helper'
require 'flipper/adapters/v2/pstore'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::PStore do
  subject {
    dir = FlipperRoot.join("tmp").tap { |d| d.mkpath }
    pstore_file = dir.join("flipper.pstore")
    pstore_file.unlink if pstore_file.exist?
    described_class.new(pstore_file)
  }

  it_should_behave_like 'a v2 flipper adapter'

  it "defaults path to flipper.pstore" do
    expect(described_class.new.path).to eq("flipper.pstore")
  end
end
