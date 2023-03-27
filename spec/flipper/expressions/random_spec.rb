RSpec.describe Flipper::Expressions::Random do
  describe "#call" do
    it "returns random number based on max" do
      100.times do
        expect(described_class.call(10)).to be_between(0, 10)
      end
    end
  end
end
