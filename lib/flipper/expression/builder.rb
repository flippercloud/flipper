module Flipper
  class Expression
    module Builder
      def build(object)
        Expression.build(object)
      end

      def add(*expressions)
        group? ? build(name => args + expressions.flatten) : any.add(*expressions)
      end

      def remove(*expressions)
        group? ? build(name => args - expressions.flatten) : any.remove(*expressions)
      end

      def any
        any? ? self : build({ Any: [self] })
      end

      def all
        all? ? self : build({ All: [self] })
      end

      def equal(object)
        build({ Equal: [self, object] })
      end
      alias eq equal

      def not_equal(object)
        build({ NotEqual: [self, object] })
      end
      alias neq not_equal

      def greater_than(object)
        build({ GreaterThan: [self, object] })
      end
      alias gt greater_than

      def greater_than_or_equal_to(object)
        build({ GreaterThanOrEqualTo: [self, object] })
      end
      alias gte greater_than_or_equal_to
      alias greater_than_or_equal greater_than_or_equal_to

      def less_than(object)
        build({ LessThan: [self, object] })
      end
      alias lt less_than

      def less_than_or_equal_to(object)
        build({ LessThanOrEqualTo: [self, object] })
      end
      alias lte less_than_or_equal_to
      alias less_than_or_equal less_than_or_equal_to

      def percentage_of_actors(object)
        build({ PercentageOfActors: [self, build(object)] })
      end

      def any?
        is_a?(Expression) && function == Expressions::Any
      end

      def all?
        is_a?(Expression) && function == Expressions::All
      end

      def group?
        any? || all?
      end
    end
  end
end
