RSpec.describe Flipper::Expressions::Percentage do
  describe "#evaluate" do
    it "returns numeric" do
      expect(described_class.new(10).evaluate).to be(10.0)
    end

    it "returns 0 if less than 0" do
      expect(described_class.new(-1).evaluate).to be(0)
    end

    it "returns 100 if greater than 100" do
      expect(described_class.new(101).evaluate).to be(100)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([99])

      expect(expression.value).to eq({"Percentage" => [99]})
    end
  end
end
