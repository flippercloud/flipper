RSpec.describe Flipper::Expressions::Duration do
  describe "#evaluate" do
    it "raises error with invalid value" do
      expect { described_class.new([false, 'minute']).evaluate }.to raise_error(ArgumentError)
    end

    it "raises error with invalid unit" do
      expect { described_class.new([4, 'score']).evaluate }.to raise_error(ArgumentError)
    end

    it 'defaults unit to seconds' do
      expect(described_class.new(10).evaluate).to eq(10)
    end

    it "evaluates seconds" do
      expect(described_class.new([10, 'seconds']).evaluate).to eq(10)
    end

    it "evaluates minutes" do
      expect(described_class.new([2, 'minutes']).evaluate).to eq(120)
    end

    it "evaluates hours" do
      expect(described_class.new([2, 'hours']).evaluate).to eq(7200)
    end

    it "evaluates days" do
      expect(described_class.new([2, 'days']).evaluate).to eq(172_800)
    end

    it "evaluates weeks" do
      expect(described_class.new([2, 'weeks']).evaluate).to eq(1_209_600)
    end

    it "evaluates months" do
      expect(described_class.new([2, 'months']).evaluate).to eq(5_259_492)
    end

    it "evaluates years" do
      expect(described_class.new([2, 'years']).evaluate).to eq(63_113_904)
    end
  end
end
