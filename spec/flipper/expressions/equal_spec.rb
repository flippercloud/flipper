require 'helper'

RSpec.describe Flipper::Expressions::Equal do
  it "can be built" do
    expression = described_class.build({
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

  it "can be built with primitives" do
    expression = described_class.build({
      "Equal" => ["basic", "basic"],
    })

    expect(expression).to be_instance_of(Flipper::Expressions::Equal)
    expect(expression.args).to eq(["basic", "basic"])
  end

  describe "#evaluate" do
    it "returns true when equal" do
      expression = described_class.new([
        Flipper.value("basic"),
        Flipper.value("basic"),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns true when properties equal" do
      expression = described_class.new([
        Flipper.property(:first),
        Flipper.property(:second),
      ])

      properties = {
        "first" => "foo",
        "second" => "foo",
      }
      expect(expression.evaluate(properties: properties)).to be(true)
    end

    it "works when nested" do
      expression = described_class.new([
        Flipper.value(true),
        Flipper.all(
          Flipper.property(:stinky).eq(true),
          Flipper.value("admin").eq(Flipper.property(:role)),
        ),
      ])

      properties = {
        "stinky" => true,
        "role" => "admin",
      }
      expect(expression.evaluate(properties: properties)).to be(true)
    end

    it "returns false when not equal" do
      expression = described_class.new([
        Flipper.value("basic"),
        Flipper.value("plus"),
      ])

      expect(expression.evaluate).to be(false)
    end

    it "returns false when properties not equal" do
      expression = described_class.new([
        Flipper.property(:first),
        Flipper.property(:second),
      ])

      properties = {
        "first" => "foo",
        "second" => "bar",
      }
      expect(expression.evaluate(properties: properties)).to be(false)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([
        Flipper::Expressions::Property.new(["plan"]),
        Flipper.value("basic"),
      ])

      expect(expression.value).to eq({
        "Equal" => [
          {"Property" => ["plan"]},
          {"Value" => ["basic"]},
        ],
      })
    end
  end
end
