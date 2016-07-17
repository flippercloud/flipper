require 'test_helper'
require 'flipper/adapters/v2/pstore'

class PstoreTest < MiniTest::Test
  prepend Flipper::Test::V2SharedAdapterTests

  def setup
    dir = FlipperRoot.join("tmp").tap { |d| d.mkpath }
    pstore_file = dir.join("flipper.pstore")
    pstore_file.unlink if pstore_file.exist?
    @adapter = Flipper::Adapters::V2::PStore.new(pstore_file)
  end

  def test_defaults_path_to_flipper_pstore
    assert_equal Flipper::Adapters::V2::PStore.new.path, "flipper.pstore"
  end
end
