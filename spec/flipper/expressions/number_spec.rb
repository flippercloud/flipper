RSpec.describe Flipper::Expressions::Number do
  describe "#initialize" do
    it "works with number" do
      expect(described_class.new(1).args).to eq([1])
    end

    it "works with array" do
      expect(described_class.new([1]).args).to eq([1])
    end
  end

  describe "#evaluate" do
    it "returns Numeric" do
      expression = described_class.new([10])
      result = expression.evaluate
      expect(result).to be(10.0)
    end

    it "returns Numeric for String" do
      expression = described_class.new(['10'])
      result = expression.evaluate
      expect(result).to be(10.0)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([99])
      expect(expression.value).to eq({"Number" => [99]})
    end
  end
end
