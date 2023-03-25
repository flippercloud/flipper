RSpec.describe Flipper::Expressions::Random do
  describe "#evaluate" do
    it "returns random number based on max" do
      100.times do
        expect(described_class.new(10).evaluate).to be_between(0, 10)
      end
    end

    it "returns random number based on max that is Value" do
      100.times do
        expect(described_class.new([Flipper.number(10)]).evaluate).to be_between(0, 10)
      end
    end
  end

  describe "#value" do
    it "returns Hash" do
      expect(described_class.new(100).value).to eq({ "Random" => [100] })
    end
  end
end
