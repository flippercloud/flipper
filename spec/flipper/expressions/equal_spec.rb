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
      Flipper::Expressions::Value.new(["basic"]),
      Flipper::Expressions::Value.new(["basic"]),
    ])
  end

  describe "#evaluate" do
    it "returns true when equal" do
      expression = described_class.new([
        Flipper::Expressions::Value.new(["basic"]),
        Flipper::Expressions::Value.new(["basic"]),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns false when not equal" do
      expression = described_class.new([
        Flipper::Expressions::Value.new(["basic"]),
        Flipper::Expressions::Value.new(["plus"]),
      ])

      expect(expression.evaluate).to be(false)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([
        Flipper::Expressions::Property.new(["plan"]),
        Flipper::Expressions::Value.new(["basic"]),
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
