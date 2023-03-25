RSpec.describe Flipper::Expressions::Property do
  describe "#evaluate" do
    it "returns value for property key" do
      expression = described_class.new("flipper_id")
      properties = {
        "flipper_id" => "User;1",
      }
      expect(expression.evaluate(properties: properties)).to eq("User;1")
    end

    it "can evalute arg and use result for property name" do
      expression = described_class.new(Flipper.property(:rollout_key))
      properties = {
        "rollout_key" => "flipper_id",
        "flipper_id" => "User;1",
      }
      expect(expression.evaluate(properties: properties)).to eq("User;1")
    end

    it "returns nil if key not found in properties" do
      expression = described_class.new("flipper_id")
      expect(expression.evaluate).to be(nil)
    end
  end

  describe "#value" do
    it "returns Hash" do
      expression = described_class.new([
        "flipper_id",
      ])

      expect(expression.value).to eq({
        "Property" => ["flipper_id"],
      })
    end
  end
end
