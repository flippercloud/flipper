require 'test_helper'
require 'flipper/adapters/pstore'

class PstoreTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    @tempfile = Tempfile.new('flipper.pstore')
    @adapter = Flipper::Adapters::PStore.new(@tempfile.path)
  end

  def teardown
    @tempfile.unlink
  end

  def test_defaults_path_to_flipper_pstore
    assert_equal Flipper::Adapters::PStore.new.path, 'flipper.pstore'
  end
end
