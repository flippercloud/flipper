RSpec.describe Flipper::Expressions::Value do
  describe "#initialize" do
    it "works with string" do
      expect(described_class.new("basic").args).to eq(["basic"])
    end

    it "works with number" do
      expect(described_class.new(1).args).to eq([1])
    end

    it "works with array" do
      expect(described_class.new(["basic"]).args).to eq(["basic"])
      expect(described_class.new(["basic"]).args).to eq(["basic"])
    end
  end

  describe "#evaluate" do
    it "returns arg" do
      expression = described_class.new(["basic"])
      expect(expression.evaluate).to eq("basic")
    end

    it "returns arg when it needs evaluation" do
      expression = described_class.new([Flipper.value("basic")])
      expect(expression.evaluate).to eq("basic")
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([20])

      expect(expression.value).to eq({
        "Value" => [20],
      })
    end
  end
end
