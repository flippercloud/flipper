require "flipper/adapters/actor_limit"

RSpec.describe Flipper::Adapters::ActorLimit do
  it_should_behave_like 'a flipper adapter' do
    let(:limit) { 5 }
    let(:adapter) { Flipper::Adapters::ActorLimit.new(Flipper::Adapters::Memory.new, limit) }

    subject { adapter }

    describe '#enable' do
      it "fails when limit exceeded" do
        5.times { |i| feature.enable Flipper::Actor.new("User;#{i}") }

        expect {
          feature.enable Flipper::Actor.new("User;6")
        }.to raise_error(Flipper::Adapters::ActorLimit::LimitExceeded)
      end

      it "allows enabling an existing actor when the limit is reached" do
        5.times { |i| feature.enable Flipper::Actor.new("User;#{i}") }

        expect {
          feature.enable Flipper::Actor.new("User;0")
        }.not_to raise_error
        expect(feature.actors_value.size).to eq(5)
        expect(feature.enabled?(Flipper::Actor.new("User;0"))).to be(true)
      end

      it "allows exceeding limit when in sync mode" do
        5.times { |i| feature.enable Flipper::Actor.new("User;#{i}") }

        described_class.with_sync_mode do
          expect {
            feature.enable Flipper::Actor.new("User;6")
          }.not_to raise_error
        end
      end
    end
  end

  describe '.sync_mode' do
    after do
      described_class.sync_mode = nil
    end

    it 'defaults to nil/falsy' do
      expect(described_class.sync_mode).to be_falsy
    end

    it 'can be set and read' do
      described_class.sync_mode = true
      expect(described_class.sync_mode).to be true
    end
  end

  describe '.with_sync_mode' do
    after do
      described_class.sync_mode = nil
    end

    it 'sets sync_mode to true within block' do
      described_class.with_sync_mode do
        expect(described_class.sync_mode).to be true
      end
    end

    it 'restores previous value after block' do
      expect(described_class.sync_mode).to be_falsy
      described_class.with_sync_mode { }
      expect(described_class.sync_mode).to be_falsy
    end

    it 'restores previous value even on exception' do
      expect {
        described_class.with_sync_mode { raise "boom" }
      }.to raise_error("boom")
      expect(described_class.sync_mode).to be_falsy
    end

    it 'returns the block result' do
      result = described_class.with_sync_mode { 42 }
      expect(result).to eq(42)
    end
  end
end
