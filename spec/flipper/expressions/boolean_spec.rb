RSpec.describe Flipper::Expressions::Boolean do
  describe "#initialize" do
    it "works with TrueClass" do
      expect(described_class.new(true).args).to eq([true])
    end

    it "works with FalseClass" do
      expect(described_class.new(false).args).to eq([false])
    end

    it "works with array" do
      expect(described_class.new([true]).args).to eq([true])
    end
  end

  describe "#evaluate" do
    it "returns a true" do
      expression = described_class.new([true])
      result = expression.evaluate
      expect(result).to be(true)
    end

    it "returns a false" do
      expression = described_class.new([false])
      result = expression.evaluate
      expect(result).to be(false)
    end

    it "returns true for String" do
      expression = described_class.new([""])
      result = expression.evaluate
      expect(result).to be(true)
    end

    it "returns true for Numeric" do
      expression = described_class.new([0])
      result = expression.evaluate
      expect(result).to be(true)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([true])
      expect(expression.value).to eq({"Boolean" => [true]})
    end
  end
end
