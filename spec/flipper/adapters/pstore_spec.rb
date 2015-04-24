require 'helper'
require 'flipper/adapters/pstore'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::PStore do
  subject { described_class.new(FlipperRoot.join("tmp", "flipper.pstore")) }

  it_should_behave_like 'a flipper adapter'

  it "defaults path to flipper.pstore" do
    described_class.new.path.should eq("flipper.pstore")
  end
end
