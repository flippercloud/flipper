module Flipper
  module Test
    module SharedAdapterTests
      def setup
        super
        @flipper = Flipper.new(@adapter)
        @feature = @flipper[:stats]
        @boolean_gate = @feature.gate(:boolean)
        @group_gate = @feature.gate(:group)
        @expression_gate = @feature.gate(:expression)
        @actor_gate = @feature.gate(:actor)
        @actors_gate = @feature.gate(:percentage_of_actors)
        @time_gate = @feature.gate(:percentage_of_time)

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

      def test_knows_how_to_get_adapter_from_source
        adapter = Flipper::Adapters::Memory.new
        flipper = Flipper.new(adapter)

        assert_includes adapter.class.from(adapter).class.ancestors, Flipper::Adapter
        assert_includes adapter.class.from(flipper).class.ancestors, Flipper::Adapter
      end

      def test_returns_correct_default_values_for_gates_if_none_are_enabled
        assert_equal @adapter.class.default_config, @adapter.get(@feature)
        assert_equal @adapter.default_config, @adapter.get(@feature)
      end

      def test_can_enable_disable_and_get_value_for_boolean_gate
        assert_equal true, @adapter.enable(@feature, @boolean_gate, Flipper::Types::Boolean.new)
        assert_equal 'true', @adapter.get(@feature)[:boolean]
        assert_equal true, @adapter.disable(@feature, @boolean_gate, Flipper::Types::Boolean.new(false))
        assert_nil @adapter.get(@feature)[:boolean]
      end

      def test_fully_disables_all_enabled_things_when_boolean_gate_disabled
        actor22 = Flipper::Actor.new('22')
        assert_equal true, @adapter.enable(@feature, @boolean_gate, Flipper::Types::Boolean.new)
        assert_equal true, @adapter.enable(@feature, @group_gate, @flipper.group(:admins))
        assert_equal true, @adapter.enable(@feature, @actor_gate, Flipper::Types::Actor.new(actor22))
        assert_equal true, @adapter.enable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(25))
        assert_equal true, @adapter.enable(@feature, @time_gate, Flipper::Types::PercentageOfTime.new(45))
        assert_equal true, @adapter.disable(@feature, @boolean_gate, Flipper::Types::Boolean.new(false))
        assert_equal @adapter.default_config, @adapter.get(@feature)
      end

      def test_can_enable_disable_and_get_value_for_expression_gate
        basic_expression = Flipper.property(:plan).eq("basic")
        age_expression = Flipper.property(:age).gte(21)
        any_expression = Flipper.any(basic_expression, age_expression)

        assert_equal true, @adapter.enable(@feature, @expression_gate, any_expression)
        result = @adapter.get(@feature)
        assert_equal any_expression.value, result[:expression]

        assert_equal true, @adapter.enable(@feature, @expression_gate, basic_expression)
        result = @adapter.get(@feature)
        assert_equal basic_expression.value, result[:expression]

        assert_equal true, @adapter.disable(@feature, @expression_gate, basic_expression)
        result = @adapter.get(@feature)
        assert_nil result[:expression]
      end

      def test_can_enable_disable_get_value_for_group_gate
        assert_equal true, @adapter.enable(@feature, @group_gate, @flipper.group(:admins))
        assert_equal true, @adapter.enable(@feature, @group_gate, @flipper.group(:early_access))

        result = @adapter.get(@feature)
        assert_equal Set['admins', 'early_access'], result[:groups]

        assert_equal true, @adapter.disable(@feature, @group_gate, @flipper.group(:early_access))
        result = @adapter.get(@feature)
        assert_equal Set['admins'], result[:groups]

        assert_equal true, @adapter.disable(@feature, @group_gate, @flipper.group(:admins))
        result = @adapter.get(@feature)
        assert_equal Set.new, result[:groups]
      end

      def test_can_enable_disable_and_get_value_for_an_actor_gate
        actor22 = Flipper::Actor.new('22')
        actor_asdf = Flipper::Actor.new('asdf')

        assert_equal true, @feature.enable(actor22)
        assert_equal true, @feature.enable(actor_asdf)

        assert @feature.enabled?(actor22)
        assert @feature.enabled?(actor_asdf)

        assert_equal true, @feature.disable(actor22)
        refute @feature.enabled?(actor22)
        assert @feature.enabled?(actor_asdf)

        assert_equal true, @feature.disable(actor_asdf)
        refute @feature.enabled?(actor22)
        refute @feature.enabled?(actor_asdf)
      end

      def test_can_enable_disable_get_value_for_percentage_of_actors_gate
        assert_equal true, @adapter.enable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(15))
        result = @adapter.get(@feature)
        assert_equal '15', result[:percentage_of_actors]

        assert_equal true, @adapter.disable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(0))
        result = @adapter.get(@feature)
        assert_equal '0', result[:percentage_of_actors]
      end

      def test_can_enable_percentage_of_actors_gate_many_times_and_consistently_return_values
        (1..100).each do |percentage|
          assert_equal true, @adapter.enable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(percentage))
          result = @adapter.get(@feature)
          assert_equal percentage.to_s, result[:percentage_of_actors]
        end
      end

      def test_can_disable_percentage_of_actors_gate_many_times_and_consistently_return_values
        (1..100).each do |percentage|
          assert_equal true, @adapter.disable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(percentage))
          result = @adapter.get(@feature)
          assert_equal percentage.to_s, result[:percentage_of_actors]
        end
      end

      def test_can_enable_disable_and_get_value_for_percentage_of_time_gate
        assert_equal true, @adapter.enable(@feature, @time_gate, Flipper::Types::PercentageOfTime.new(10))
        result = @adapter.get(@feature)
        assert_equal '10', result[:percentage_of_time]

        assert_equal true, @adapter.disable(@feature, @time_gate, Flipper::Types::PercentageOfTime.new(0))
        result = @adapter.get(@feature)
        assert_equal '0', result[:percentage_of_time]
      end

      def test_can_enable_percentage_of_time_gate_many_times_and_consistently_return_values
        (1..100).each do |percentage|
          assert_equal true, @adapter.enable(@feature, @time_gate, Flipper::Types::PercentageOfTime.new(percentage))
          result = @adapter.get(@feature)
          assert_equal percentage.to_s, result[:percentage_of_time]
        end
      end

      def test_can_disable_percentage_of_time_gate_many_times_and_consistently_return_values
        (1..100).each do |percentage|
          assert_equal true, @adapter.disable(@feature, @time_gate, Flipper::Types::PercentageOfTime.new(percentage))
          result = @adapter.get(@feature)
          assert_equal percentage.to_s, result[:percentage_of_time]
        end
      end

      def test_converts_boolean_value_to_a_string
        assert_equal true, @adapter.enable(@feature, @boolean_gate, Flipper::Types::Boolean.new)
        result = @adapter.get(@feature)
        assert_equal 'true', result[:boolean]
      end

      def test_converts_the_actor_value_to_a_string
        actor = Flipper::Actor.new(22)
        refute @feature.enabled?(actor)
        @feature.enable_actor actor
        assert @feature.enabled?(actor)
      end

      def test_converts_group_value_to_a_string
        assert_equal  true, @adapter.enable(@feature, @group_gate, @flipper.group(:admins))
        result = @adapter.get(@feature)
        assert_equal Set['admins'], result[:groups]
      end

      def test_converts_percentage_of_time_integer_value_to_a_string
        assert_equal true, @adapter.enable(@feature, @time_gate, Flipper::Types::PercentageOfTime.new(10))
        result = @adapter.get(@feature)
        assert_equal '10', result[:percentage_of_time]
      end

      def test_converts_percentage_of_actors_integer_value_to_a_string
        assert_equal true, @adapter.enable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(10))
        result = @adapter.get(@feature)
        assert_equal '10', result[:percentage_of_actors]
      end

      def test_can_add_remove_and_list_known_features
        assert_equal Set.new, @adapter.features

        assert_equal true, @adapter.add(@flipper[:stats])
        assert_equal Set['stats'], @adapter.features

        assert_equal true, @adapter.add(@flipper[:search])
        assert_equal Set['stats', 'search'], @adapter.features

        assert_equal true, @adapter.remove(@flipper[:stats])
        assert_equal Set['search'], @adapter.features

        assert_equal true, @adapter.remove(@flipper[:search])
        assert_equal Set.new, @adapter.features
      end

      def test_clears_all_the_gate_values_for_the_feature_on_remove
        actor22 = Flipper::Actor.new('22')
        assert_equal true, @adapter.enable(@feature, @boolean_gate, Flipper::Types::Boolean.new)
        assert_equal true, @adapter.enable(@feature, @group_gate, @flipper.group(:admins))
        assert_equal true, @adapter.enable(@feature, @actor_gate, Flipper::Types::Actor.new(actor22))
        assert_equal true, @adapter.enable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(25))
        assert_equal true, @adapter.enable(@feature, @time_gate, Flipper::Types::PercentageOfTime.new(45))

        assert_equal true, @adapter.remove(@feature)

        assert_equal @adapter.default_config, @adapter.get(@feature)
      end

      def test_can_clear_all_the_gate_values_for_a_feature
        actor22 = Flipper::Actor.new('22')
        @adapter.add(@feature)
        assert_includes @adapter.features, @feature.key

        assert_equal true, @adapter.enable(@feature, @boolean_gate, Flipper::Types::Boolean.new)
        assert_equal true, @adapter.enable(@feature, @group_gate, @flipper.group(:admins))
        assert_equal true, @adapter.enable(@feature, @actor_gate, Flipper::Types::Actor.new(actor22))
        assert_equal true, @adapter.enable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(25))
        assert_equal true, @adapter.enable(@feature, @time_gate, Flipper::Types::PercentageOfTime.new(45))

        assert_equal true, @adapter.clear(@feature)
        assert_includes @adapter.features, @feature.key
        assert_equal @adapter.default_config, @adapter.get(@feature)
      end

      def test_does_not_complain_clearing_a_feature_that_does_not_exist_in_adapter
        assert_equal true, @adapter.clear(@flipper[:stats])
      end

      def test_can_get_multiple_features
        assert @adapter.add(@flipper[:stats])
        assert @adapter.enable(@flipper[:stats], @boolean_gate, Flipper::Types::Boolean.new)
        assert @adapter.add(@flipper[:search])

        result = @adapter.get_multi([@flipper[:stats], @flipper[:search], @flipper[:other]])
        assert_instance_of Hash, result

        stats = result["stats"]
        search = result["search"]
        other = result["other"]
        assert_equal @adapter.default_config.merge(boolean: 'true'), stats
        assert_equal @adapter.default_config, search
        assert_equal @adapter.default_config, other
      end

      def test_can_get_all_features
        assert @adapter.add(@flipper[:stats])
        assert @adapter.enable(@flipper[:stats], @boolean_gate, Flipper::Types::Boolean.new)
        assert @adapter.add(@flipper[:search])
        @flipper.enable :analytics, Flipper.property(:plan).eq("pro")

        result = @adapter.get_all

        assert_instance_of Hash, result
        assert_equal @adapter.default_config.merge(boolean: 'true'), result["stats"]
        assert_equal @adapter.default_config, result["search"]
        assert_equal @adapter.default_config.merge(expression: {"Equal"=>[{"Property"=>["plan"]}, "pro"]}), result["analytics"]
      end

      def test_includes_explicitly_disabled_features_when_getting_all_features
        @flipper.enable(:stats)
        @flipper.enable(:search)
        @flipper.disable(:search)

        result = @adapter.get_all
        assert_equal %w(search stats), result.keys.sort
      end

      def test_can_double_enable_an_actor_without_error
        actor = Flipper::Actor.new('Flipper::Actor;22')
        assert_equal true, @feature.enable(actor)
        assert_equal true, @feature.enable(actor)
        assert @feature.enabled?(actor)
      end

      def test_can_double_enable_a_group_without_error
        assert_equal true, @adapter.enable(@feature, @group_gate, @flipper.group(:admins))
        assert_equal true, @adapter.enable(@feature, @group_gate, @flipper.group(:admins))
        assert_equal Set['admins'], @adapter.get(@feature).fetch(:groups)
      end

      def test_can_double_enable_percentage_without_error
        assert_equal true, @adapter.enable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(25))
        assert_equal true, @adapter.enable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(25))
      end

      def test_can_double_enable_without_error
        assert_equal true, @adapter.enable(@feature, @boolean_gate, Flipper::Types::Boolean.new)
        assert_equal true, @adapter.enable(@feature, @boolean_gate, Flipper::Types::Boolean.new)
      end

      def test_can_get_all_features_when_there_are_none
        expected = {}
        assert_equal Set.new, @adapter.features
        assert_equal expected, @adapter.get_all
      end

      def test_clears_other_gate_values_on_enable
        actor = Flipper::Actor.new('Flipper::Actor;22')
        assert_equal true, @adapter.enable(@feature, @actors_gate, Flipper::Types::PercentageOfActors.new(25))
        assert_equal true, @adapter.enable(@feature, @time_gate, Flipper::Types::PercentageOfTime.new(25))
        assert_equal true, @adapter.enable(@feature, @group_gate, @flipper.group(:admins))
        assert_equal true, @adapter.enable(@feature, @actor_gate, Flipper::Types::Actor.new(actor))
        assert_equal true, @adapter.enable(@feature, @boolean_gate, Flipper::Types::Boolean.new(true))
        assert_equal @adapter.default_config.merge(boolean: "true"), @adapter.get(@feature)
      end

      def test_can_import_and_export
        adapter = Flipper::Adapters::Memory.new
        source_flipper = Flipper.new(adapter)
        source_flipper.enable(:stats)
        export = adapter.export

        # some adapters cannot import so if they return false lets assert it
        # didn't happen
        if @adapter.import(export)
          assert @flipper[:stats].enabled?
        else
          refute @flipper[:stats].enabled?
        end
      end
    end
  end
end
