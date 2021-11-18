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
end
