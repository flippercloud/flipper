RSpec.describe Flipper::Expressions::Random do
  describe "#initialize" do
    it "works with number" do
      expect(described_class.new(1).args).to eq([1])
    end

    it "works with array" do
      expect(described_class.new([1]).args).to eq([1])
    end
  end

  describe "#evaluate" do
    it "returns random number based on seed" do
      expression = described_class.new([10])
      result = expression.evaluate
      expect(result).to be >= 0
      expect(result).to be <= 10
    end

    it "returns random number based on seed that is Value" do
      expression = described_class.new([Flipper.number(10)])
      result = expression.evaluate
      expect(result).to be >= 0
      expect(result).to be <= 10
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([100])

      expect(expression.value).to eq({
        "Random" => [100],
      })
    end
  end
end
