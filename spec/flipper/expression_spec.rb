require 'helper'

RSpec.describe Flipper::Expression do
  describe "#build" do
    it "can build Equal" do
      expression = Flipper::Expression.build({
        "Equal" => [
          {"Value" => ["basic"]},
          {"Value" => ["basic"]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::Equal)
      expect(expression.args).to eq([
        Flipper.value("basic"),
        Flipper.value("basic"),
      ])
    end

    it "can build GreaterThanOrEqual" do
      expression = Flipper::Expression.build({
        "GreaterThanOrEqual" => [
          {"Value" => [2]},
          {"Value" => [1]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::GreaterThanOrEqual)
      expect(expression.args).to eq([
        Flipper.value(2),
        Flipper.value(1),
      ])
    end

    it "can build GreaterThan" do
      expression = Flipper::Expression.build({
        "GreaterThan" => [
          {"Value" => [2]},
          {"Value" => [1]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::GreaterThan)
      expect(expression.args).to eq([
        Flipper.value(2),
        Flipper.value(1),
      ])
    end

    it "can build LessThanOrEqual" do
      expression = Flipper::Expression.build({
        "LessThanOrEqual" => [
          {"Value" => [2]},
          {"Value" => [1]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::LessThanOrEqual)
      expect(expression.args).to eq([
        Flipper.value(2),
        Flipper.value(1),
      ])
    end

    it "can build LessThan" do
      expression = Flipper::Expression.build({
        "LessThan" => [
          {"Value" => [2]},
          {"Value" => [1]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::LessThan)
      expect(expression.args).to eq([
        Flipper.value(2),
        Flipper.value(1),
      ])
    end

    it "can build NotEqual" do
      expression = Flipper::Expression.build({
        "NotEqual" => [
          {"Value" => ["basic"]},
          {"Value" => ["plus"]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::NotEqual)
      expect(expression.args).to eq([
        Flipper.value("basic"),
        Flipper.value("plus"),
      ])
    end

    it "can build Value" do
      expression = Flipper::Expression.build({
        "Value" => [1]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::Value)
      expect(expression.args).to eq([1])
    end

    it "can build Percentage" do
      expression = Flipper::Expression.build({
        "Percentage" => [
          {"Value" => ["User;1"]},
          {"Value" => [40]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::Percentage)
      expect(expression.args).to eq([
        Flipper.value("User;1"),
        Flipper.value(40),
      ])
    end

    it "can build Value" do
      expression = Flipper::Expression.build({
        "Value" => ["basic"]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::Value)
      expect(expression.args).to eq(["basic"])
    end
  end

  describe "#initialize" do
    it "works with Array" do
      expect(described_class.new([1]).args).to eq([1])
    end

    it "raises ArgumentError if not Array" do
      [
        "asdf",
        1,
        {"foo" => "bar"},
      ].each do |value|
        expect {
          described_class.new(value)
        }.to raise_error(ArgumentError, /args must be an Array but was #{value.inspect}/)
      end
    end
  end

  describe "#eql?" do
    it "returns true for same class and args" do
      expression = Flipper::Expression.new(["foo"])
      other = Flipper::Expression.new(["foo"])
      expect(expression.eql?(other)).to be(true)
    end

    it "returns false for different class" do
      expression = Flipper::Expression.new(["foo"])
      other = Object.new
      expect(expression.eql?(other)).to be(false)
    end

    it "returns false for different args" do
      expression = Flipper::Expression.new(["foo"])
      other = Flipper::Expression.new(["bar"])
      expect(expression.eql?(other)).to be(false)
    end
  end

  describe "#==" do
    it "returns true for same class and args" do
      expression = Flipper::Expression.new(["foo"])
      other = Flipper::Expression.new(["foo"])
      expect(expression == other).to be(true)
    end

    it "returns false for different class" do
      expression = Flipper::Expression.new(["foo"])
      other = Object.new
      expect(expression == other).to be(false)
    end

    it "returns false for different args" do
      expression = Flipper::Expression.new(["foo"])
      other = Flipper::Expression.new(["bar"])
      expect(expression == other).to be(false)
    end
  end

  describe "#add" do
    it "converts to Any and adds new expressions" do
      expression = described_class.new(["something"])
      first = Flipper.value(true).eq(true)
      second = Flipper.value(false).eq(false)
      new_expression = expression.add(first, second)
      expect(new_expression).to be_instance_of(Flipper::Expressions::Any)
      expect(new_expression.args).to eq([
        expression,
        first,
        second,
      ])
    end
  end

  describe "#remove" do
    it "converts to Any and removes any expressions that match" do
      expression = described_class.new(["something"])
      first = Flipper.value(true).eq(true)
      second = Flipper.value(false).eq(false)
      new_expression = expression.remove(described_class.new(["something"]), first, second)
      expect(new_expression).to be_instance_of(Flipper::Expressions::Any)
      expect(new_expression.args).to eq([])
    end
  end

  it "can convert to Any" do
    expression = described_class.new(["something"])
    converted = expression.any
    expect(converted).to be_instance_of(Flipper::Expressions::Any)
    expect(converted.args).to eq([expression])
  end

  it "can convert to All" do
    expression = described_class.new(["something"])
    converted = expression.all
    expect(converted).to be_instance_of(Flipper::Expressions::All)
    expect(converted.args).to eq([expression])
  end

  [
    [[2], [3], "equal", "eq", Flipper::Expressions::Equal],
    [[2], [3], "not_equal", "neq", Flipper::Expressions::NotEqual],
    [[2], [3], "greater_than", "gt", Flipper::Expressions::GreaterThan],
    [[2], [3], "greater_than_or_equal", "gte", Flipper::Expressions::GreaterThanOrEqual],
    [[2], [3], "less_than", "lt", Flipper::Expressions::LessThan],
    [[2], [3], "less_than_or_equal", "lte", Flipper::Expressions::LessThanOrEqual],
  ].each do |(args, other_args, method_name, shortcut_name, klass)|
    it "can convert to #{klass}" do
      expression = described_class.new(args)
      other = described_class.new(other_args)
      converted = expression.send(method_name, other)
      expect(converted).to be_instance_of(klass)
      expect(converted.args).to eq([expression, other])
    end

    it "can convert to #{klass} using #{shortcut_name}" do
      expression = described_class.new(args)
      other = described_class.new(other_args)
      converted = expression.send(shortcut_name, other)
      expect(converted).to be_instance_of(klass)
      expect(converted.args).to eq([expression, other])
    end
  end

  it "can convert to Percentage" do
    expression = Flipper.value("User;1")
    converted = expression.percentage(40)
    expect(converted).to be_instance_of(Flipper::Expressions::Percentage)
    expect(converted.args).to eq([
      expression,
      Flipper.value(40)
    ])
  end
end
