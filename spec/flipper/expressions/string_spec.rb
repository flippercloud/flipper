RSpec.describe Flipper::Expressions::String do
  describe "#initialize" do
    it "works with string" do
      expect(described_class.new("test").args).to eq(["test"])
    end

    it "works with array" do
      expect(described_class.new(["test"]).args).to eq(["test"])
    end
  end

  describe "#evaluate" do
    it "returns String for Numeric" do
      expression = described_class.new([10])
      result = expression.evaluate
      expect(result).to eq("10")
    end

    it "returns String" do
      expression = described_class.new(["test"])
      result = expression.evaluate
      expect(result).to eq("test")
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new(["test"])
      expect(expression.value).to eq({"String" => ["test"]})
    end
  end
end
