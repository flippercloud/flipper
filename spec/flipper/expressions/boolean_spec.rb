RSpec.describe Flipper::Expressions::Boolean do
  describe "#call" do
    [true, 'true', 1, '1'].each do |value|
      it "returns a true for #{value.inspect}" do
        expect(described_class.call(value)).to be(true)
      end
    end

    [false, 'false', 0, '0', nil].each do |value|
      it "returns a true for #{value.inspect}" do
        expect(described_class.call(value)).to be(false)
      end
    end
  end
end
