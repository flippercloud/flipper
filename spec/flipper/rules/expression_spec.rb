require 'helper'

RSpec.describe Flipper::Expression do
  describe "#build" do
    it "can build Equal" do
      expression = Flipper::Expression.build({
        "Equal" => [
          {"String" => ["basic"]},
          {"String" => ["basic"]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::Equal)
      expect(expression.args).to eq([
        Flipper::Expressions::String.new(["basic"]),
        Flipper::Expressions::String.new(["basic"]),
      ])
    end

    it "can build GreaterThanOrEqual" do
      expression = Flipper::Expression.build({
        "GreaterThanOrEqual" => [
          {"Number" => [2]},
          {"Number" => [1]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::GreaterThanOrEqual)
      expect(expression.args).to eq([
        Flipper::Expressions::Number.new([2]),
        Flipper::Expressions::Number.new([1]),
      ])
    end

    it "can build GreaterThan" do
      expression = Flipper::Expression.build({
        "GreaterThan" => [
          {"Number" => [2]},
          {"Number" => [1]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::GreaterThan)
      expect(expression.args).to eq([
        Flipper::Expressions::Number.new([2]),
        Flipper::Expressions::Number.new([1]),
      ])
    end

    it "can build LessThanOrEqual" do
      expression = Flipper::Expression.build({
        "LessThanOrEqual" => [
          {"Number" => [2]},
          {"Number" => [1]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::LessThanOrEqual)
      expect(expression.args).to eq([
        Flipper::Expressions::Number.new([2]),
        Flipper::Expressions::Number.new([1]),
      ])
    end

    it "can build LessThan" do
      expression = Flipper::Expression.build({
        "LessThan" => [
          {"Number" => [2]},
          {"Number" => [1]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::LessThan)
      expect(expression.args).to eq([
        Flipper::Expressions::Number.new([2]),
        Flipper::Expressions::Number.new([1]),
      ])
    end

    it "can build NotEqual" do
      expression = Flipper::Expression.build({
        "NotEqual" => [
          {"String" => ["basic"]},
          {"String" => ["plus"]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::NotEqual)
      expect(expression.args).to eq([
        Flipper::Expressions::String.new(["basic"]),
        Flipper::Expressions::String.new(["plus"]),
      ])
    end

    it "can build Number" do
      expression = Flipper::Expression.build({
        "Number" => [1]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::Number)
      expect(expression.args).to eq([1])
    end

    it "can build Percentage" do
      expression = Flipper::Expression.build({
        "Percentage" => [
          {"String" => ["User;1"]},
          {"Number" => [40]},
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::Percentage)
      expect(expression.args).to eq([
        Flipper::Expressions::String.new(["User;1"]),
        Flipper::Expressions::Number.new([40]),
      ])
    end

    it "can build String" do
      expression = Flipper::Expression.build({
        "String" => ["basic"]
      })

      expect(expression).to be_instance_of(Flipper::Expressions::String)
      expect(expression.args).to eq(["basic"])
    end
  end
end
