require 'helper'

RSpec.describe Flipper::Expressions::Equal do
  it "can be built" do
    expression = described_class.build({
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

  describe "#evaluate" do
    it "returns true when equal" do
      expression = Flipper::Expressions::Equal.new([
        Flipper::Expressions::String.new(["basic"]),
        Flipper::Expressions::String.new(["basic"]),
      ])

      expect(expression.evaluate).to be(true)
    end

    it "returns false when not equal" do
      expression = Flipper::Expressions::Equal.new([
        Flipper::Expressions::String.new(["basic"]),
        Flipper::Expressions::String.new(["plus"]),
      ])

      expect(expression.evaluate).to be(false)
    end
  end
end
