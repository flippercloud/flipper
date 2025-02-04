RSpec.describe Flipper::Adapters::Strict do
  let(:flipper) { Flipper.new(subject) }
  let(:feature) { flipper[:unknown] }

  it_should_behave_like 'a flipper adapter' do
    subject { described_class.new(Flipper::Adapters::Memory.new, :noop) }
  end

  [true, :raise].each do |handler|
    context "handler = #{handler}" do
      subject { described_class.new(Flipper::Adapters::Memory.new, handler) }

      context "#get" do
        it "raises an error for unknown feature" do
          expect { subject.get(feature) }.to raise_error(Flipper::Adapters::Strict::NotFound)
        end
      end

      context "#get_multi" do
        it "raises an error for unknown feature" do
          expect { subject.get_multi([feature]) }.to raise_error(Flipper::Adapters::Strict::NotFound)
        end
      end
    end
  end

  context "handler = :warn" do
    subject { described_class.new(Flipper::Adapters::Memory.new, :warn) }

    context "#get" do
      it "raises an error for unknown feature" do
        expect(capture_output { subject.get(feature) }).to match(/Could not find feature "unknown"/)
      end
    end

    context "#get_multi" do
      it "raises an error for unknown feature" do
        expect(capture_output { subject.get_multi([feature]) }).to match(/Could not find feature "unknown"/)
      end
    end
  end

  context "handler = Block" do
    let(:unknown_features) { [] }
    subject do
      described_class.new(Flipper::Adapters::Memory.new) { |feature| unknown_features << feature.key}
    end


    context "#get" do
      it "raises an error for unknown feature" do
        subject.get(feature)
        expect(unknown_features).to eq(["unknown"])
      end
    end

    context "#get_multi" do
      it "raises an error for unknown feature" do
        subject.get_multi([flipper[:foo], flipper[:bar]])
        expect(unknown_features).to eq(["foo", "bar"])
      end
    end
  end
end
