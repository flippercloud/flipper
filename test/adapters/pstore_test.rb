require 'test_helper'

class PstoreTest < TestCase
  prepend Flipper::Test::SharedAdapterTests

  def before_all
    require 'flipper/adapters/pstore'
  end

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
