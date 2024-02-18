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
    end
  end
end
