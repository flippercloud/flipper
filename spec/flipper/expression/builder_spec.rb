RSpec.describe Flipper::Expression::Builder do
  def build(object)
    Flipper::Expression.build(object)
  end

  describe "#add" do
    it "converts to Any and adds new expressions" do
      expression = build("something")
      first = Flipper.boolean(true).eq(true)
      second = Flipper.boolean(false).eq(false)
      new_expression = expression.add(first, second)
      expect(new_expression).to eq(build({ Any: ["something", first, second] }))
    end
  end

  describe "#remove" do
    it "converts to Any and removes any expressions that match" do
      expression = build("something")
      first = Flipper.boolean(true).eq(true)
      second = Flipper.boolean(false).eq(false)
      new_expression = expression.remove(build("something"), first, second)
      expect(new_expression).to eq(build(Any: []))
    end
  end

  it "can convert to Any" do
    expression = build("something")
    converted = expression.any
    expect(converted).to be_instance_of(Flipper::Expression)
    expect(converted.function).to be(Flipper::Expressions::Any)
    expect(converted.args).to eq([expression])
  end

  it "can convert to All" do
    expression = build("something")
    converted = expression.all
    expect(converted).to eq(build(All: ["something"]))
  end

  context "Any" do
    describe "#any" do
      it "returns self" do
        expression = build(Any: [
          Flipper.boolean(true),
          Flipper.string("yep").eq("yep"),
        ])
        expect(expression.any).to be(expression)
      end
    end

    describe "#add" do
      it "returns new instance with expression added" do
        expression = Flipper.boolean(true)
        other = Flipper.string("yep").eq("yep")

        result = expression.add(other)
        expect(result.args).to eq([
          Flipper.boolean(true),
          Flipper.string("yep").eq("yep"),
        ])
      end

      it "returns new instance with many expressions added" do
        expression = Flipper.boolean(true)
        second = Flipper.string("yep").eq("yep")
        third = Flipper.number(1).lte(20)

        result = expression.add(second, third)
        expect(result.args).to eq([
          Flipper.boolean(true),
          Flipper.string("yep").eq("yep"),
          Flipper.number(1).lte(20),
        ])
      end

      it "returns new instance with array of expressions added" do
        expression = Flipper.boolean(true)
        second = Flipper.string("yep").eq("yep")
        third = Flipper.number(1).lte(20)

        result = expression.add([second, third])
        expect(result.args).to eq([
          Flipper.boolean(true),
          Flipper.string("yep").eq("yep"),
          Flipper.number(1).lte(20),
        ])
      end
    end

    describe "#remove" do
      it "returns new instance with expression removed" do
        first = Flipper.boolean(true)
        second = Flipper.string("yep").eq("yep")
        third = Flipper.number(1).lte(20)
        expression = Flipper.any([first, second, third])

        result = expression.remove(second)
        expect(expression.args).to eq([first, second, third])
        expect(result.args).to eq([first, third])
      end

      it "returns new instance with many expressions removed" do
        first = Flipper.boolean(true)
        second = Flipper.string("yep").eq("yep")
        third = Flipper.number(1).lte(20)
        expression = Flipper.any([first, second, third])

        result = expression.remove(second, third)
        expect(expression.args).to eq([first, second, third])
        expect(result.args).to eq([first])
      end

      it "returns new instance with array of expressions removed" do
        first = Flipper.boolean(true)
        second = Flipper.string("yep").eq("yep")
        third = Flipper.number(1).lte(20)
        expression = Flipper.any([first, second, third])

        result = expression.remove([second, third])
        expect(expression.args).to eq([first, second, third])
        expect(result.args).to eq([first])
      end
    end
  end

  [
    [2, 3, "equal", "eq", :Equal],
    [2, 3, "not_equal", "neq", :NotEqual],
    [2, 3, "greater_than", "gt", :GreaterThan],
    [2, 3, "greater_than_or_equal_to", "gte", :GreaterThanOrEqualTo],
    [2, 3, "greater_than_or_equal_to", "greater_than_or_equal", :GreaterThanOrEqualTo],
    [2, 3, "less_than", "lt", :LessThan],
    [2, 3, "less_than_or_equal_to", "lte", :LessThanOrEqualTo],
    [2, 3, "less_than_or_equal_to", "less_than_or_equal", :LessThanOrEqualTo],
  ].each do |(left, right, method_name, shortcut_name, function)|
    it "can convert to #{function}" do
      expression = build(left)
      other = build(right)
      converted = expression.send(method_name, other)
      expect(converted).to eq(build({ function => [ left, right] }))
    end

    it "can convert to #{function} using #{shortcut_name}" do
      expression = build(left)
      other = build(right)
      converted = expression.send(shortcut_name, other)
      expect(converted).to eq(build({ function => [ left, right] }))
    end

    it "builds args into expressions when converting to #{function}" do
      expression = build(left)
      other = Flipper.property(:age)
      converted = expression.send(method_name, other.value)
      expect(converted).to eq(build({ function => [ left, other.value] }))
    end
  end

  it "can convert to PercentageOfActors" do
    expression = Flipper.constant("User;1").percentage_of_actors(40)
    expect(expression).to eq(build({ PercentageOfActors: [ "User;1", 40 ] }))
  end

  context "All" do
    describe "#all" do
      it "returns self" do
        expression = Flipper.all([
          Flipper.boolean(true),
          Flipper.string("yep").eq("yep"),
        ])
        expect(expression.all).to be(expression)
      end
    end

    describe "#add" do
      it "returns new instance with expression added" do
        expression = Flipper.all([Flipper.boolean(true)])
        other = Flipper.string("yep").eq("yep")

        result = expression.add(other)
        expect(result.args).to eq([
          Flipper.boolean(true),
          Flipper.string("yep").eq("yep"),
        ])
      end

      it "returns new instance with many expressions added" do
        expression = Flipper.all([Flipper.boolean(true)])
        second = Flipper.string("yep").eq("yep")
        third = Flipper.number(1).lte(20)

        result = expression.add(second, third)
        expect(result.args).to eq([
          Flipper.boolean(true),
          Flipper.string("yep").eq("yep"),
          Flipper.number(1).lte(20),
        ])
      end

      it "returns new instance with array of expressions added" do
        expression = Flipper.all([Flipper.boolean(true)])
        second = Flipper.string("yep").eq("yep")
        third = Flipper.number(1).lte(20)

        result = expression.add([second, third])
        expect(result.args).to eq([
          Flipper.boolean(true),
          Flipper.string("yep").eq("yep"),
          Flipper.number(1).lte(20),
        ])
      end
    end

    describe "#remove" do
      it "returns new instance with expression removed" do
        first = Flipper.boolean(true)
        second = Flipper.string("yep").eq("yep")
        third = Flipper.number(1).lte(20)
        expression = Flipper.all([first, second, third])

        result = expression.remove(second)
        expect(expression.args).to eq([first, second, third])
        expect(result.args).to eq([first, third])
      end

      it "returns new instance with many expressions removed" do
        first = Flipper.boolean(true)
        second = Flipper.string("yep").eq("yep")
        third = Flipper.number(1).lte(20)
        expression = Flipper.all([first, second, third])

        result = expression.remove(second, third)
        expect(expression.args).to eq([first, second, third])
        expect(result.args).to eq([first])
      end

      it "returns new instance with array of expressions removed" do
        first = Flipper.boolean(true)
        second = Flipper.string("yep").eq("yep")
        third = Flipper.number(1).lte(20)
        expression = Flipper.all([first, second, third])

        result = expression.remove([second, third])
        expect(expression.args).to eq([first, second, third])
        expect(result.args).to eq([first])
      end
    end
  end
end
