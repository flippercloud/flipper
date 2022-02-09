RSpec.describe Flipper::Expressions::Percentage do
  describe "#initialize" do
    it "works with number" do
      expect(described_class.new(1).args).to eq([1])
    end

    it "works with array" do
      expect(described_class.new([1]).args).to eq([1])
    end
  end

  describe "#evaluate" do
    it "returns numeric" do
      expression = described_class.new([10])
      result = expression.evaluate
      expect(result).to be(10.0)
    end

    it "returns 0 if less than 0" do
      expression = described_class.new([-1])
      result = expression.evaluate
      expect(result).to be(0)
    end

    it "returns 100 if greater than 100" do
      expression = described_class.new([101])
      result = expression.evaluate
      expect(result).to be(100)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([99])

      expect(expression.value).to eq({"Percentage" => [99]})
    end
  end
end
