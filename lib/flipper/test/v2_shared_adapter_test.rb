module Flipper
  module Test
    module V2SharedAdapterTests
      def setup
        super
        @flipper = Flipper.new(@adapter)
        @actor_class = Struct.new(:flipper_id)
        @feature = @flipper[:stats]
        @boolean_gate = @feature.gate(:boolean)
        @group_gate = @feature.gate(:group)
        @actor_gate = @feature.gate(:actor)
        @actors_gate = @feature.gate(:percentage_of_actors)
        @time_gate = @feature.gate(:percentage_of_time)

        Flipper.unregister_groups

        Flipper.register(:admins) do |actor|
          actor.respond_to?(:admin?) && actor.admin?
        end

        Flipper.register(:early_access) do |actor|
          actor.respond_to?(:early_access?) && actor.early_access?
        end
      end

      def teardown
        super
        Flipper.unregister_groups
      end

      def test_has_name_that_is_a_symbol
        refute_empty @adapter.name
        assert_kind_of Symbol, @adapter.name
      end

      def test_has_included_the_flipper_adapter_module
        assert_includes @adapter.class.ancestors, Flipper::Adapter
      end

      def test_knows_version
        assert_equal Flipper::Adapter::V2, @adapter.version
      end

      def test_returns_nil_when_getting_key_that_is_not_set
        assert_nil @adapter.get("foo")
      end

      def test_can_set_get_and_delete_a_key
        @adapter.set("foo", "1")
        assert_equal "1", @adapter.get("foo")
        @adapter.del("foo")
        assert_nil @adapter.get("foo")
      end

      def test_can_set_already_set_keys
        @adapter.set("foo", "old")
        assert_equal "old", @adapter.get("foo")
        @adapter.set("foo", "new")
        assert_equal "new", @adapter.get("foo")
      end

      def test_does_not_error_when_deleting_a_missing_key
        assert_nil @adapter.get("foo")
        @adapter.del("foo")
      end

      def test_always_sets_value_to_string
        @adapter.set("foo", 22)
        assert_equal "22", @adapter.get("foo")
      end
    end
  end
end
