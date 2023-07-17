RSpec.describe Flipper::Expressions::Duration do
  describe "#call" do
    it "raises error with invalid value" do
      expect { described_class.call(false, 'minute') }.to raise_error(ArgumentError)
    end

    it "raises error with invalid unit" do
      expect { described_class.call(4, 'score') }.to raise_error(ArgumentError)
    end

    it 'defaults unit to seconds' do
      expect(described_class.call(10)).to eq(10)
    end

    it "evaluates seconds" do
      expect(described_class.call(10, 'seconds')).to eq(10)
    end

    it "evaluates minutes" do
      expect(described_class.call(2, 'minutes')).to eq(120)
    end

    it "evaluates hours" do
      expect(described_class.call(2, 'hours')).to eq(7200)
    end

    it "evaluates days" do
      expect(described_class.call(2, 'days')).to eq(172_800)
    end

    it "evaluates weeks" do
      expect(described_class.call(2, 'weeks')).to eq(1_209_600)
    end

    it "evaluates months" do
      expect(described_class.call(2, 'months')).to eq(5_259_492)
    end

    it "evaluates years" do
      expect(described_class.call(2, 'years')).to eq(63_113_904)
    end
  end
end
